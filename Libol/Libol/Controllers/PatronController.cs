using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Entity;
using System.Data.Entity.Core.Objects;
using System.Data.OleDb;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Web;
using System.Web.Mvc;
using Libol.Models;
using Libol.SupportClass;

namespace Libol.Controllers
{
    public class PatronController : Controller
    {
        private LibolEntities db = new LibolEntities();
       
        public ActionResult PatronProfile()
        {
            return View();
        }

        public ActionResult Create()
        {
            ViewBag.Ethnic = db.SP_PAT_GET_ETHNIC().ToList();
            ViewBag.PatronGroup = db.SP_PAT_GET_PATRONGROUP().ToList();
            ViewBag.Education = db.SP_PAT_GET_EDUCATION().ToList();
            ViewBag.Occupation = db.SP_PAT_GET_OCCUPATION().ToList();
            ViewBag.College = db.SP_PAT_GET_COLLEGE().ToList();
            int CollegeID = db.SP_PAT_GET_COLLEGE().ToList()[0].ID;
            ViewBag.Faculty = db.CIR_DIC_FACULTY.Where(a => a.CollegeID == CollegeID).ToList();
            ViewBag.Province = db.CIR_DIC_PROVINCE.ToList();
            ViewBag.Countries = db.SP_GET_COUNTRIES().ToList();
            return View();
        }



        [HttpPost]
        public JsonResult OnchangeCollege(int CollegeID)
        {
            ViewBag.Faculty = db.CIR_DIC_FACULTY.Where(a => a.CollegeID == CollegeID).ToList();
            List<CIR_DIC_FACULTY> list = new List<CIR_DIC_FACULTY>();
            foreach (var f in ViewBag.Faculty)
            {
                list.Add(new CIR_DIC_FACULTY()
                {
                    ID = f.ID,
                    Faculty = f.Faculty,
                    CollegeID = f.CollegeID
                });
            }
            return Json(list, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public JsonResult NewPatron(string strCode, string strValidDate, string strExpiredDate, string strLastIssuedDate, string strLastName, string strFirstName,
             Nullable<bool> blnSex, string strDOB, Nullable<int> intEthnicID, Nullable<int> intEducationID, Nullable<int> intOccupationID,
            string strWorkPlace, string strTelephone, string strMobile, string strEmail, string strPortrait, Nullable<int> intPatronGroupID, string strNote,
            Nullable<int> intIsQue, string strIDCard, string strAddress, Nullable<int> intProvinceID, string strCity, Nullable<int> intCountryID, string strZip,
            Nullable<int> intisActive, int intCollegeID, int intFacultyID, string strGrade, string strClass)
        {
            string InvalidFields = "";
            if ( String.IsNullOrEmpty(strFirstName))
            {
                InvalidFields += "strFirstName-";
            }
            if (String.IsNullOrEmpty(strLastName))
            {
                InvalidFields += "strLastName-";
            }
            if (String.IsNullOrEmpty(strDOB))
            {
                InvalidFields += "strDOB-";
            }
            if (String.IsNullOrEmpty(strCode))
            {
                InvalidFields += "strCode-";
            }
            if (intPatronGroupID == null)
            {
                InvalidFields += "intPatronGroupID-";
            }
            if (String.IsNullOrEmpty(strValidDate))
            {
                InvalidFields += "strValidDate-";
            }
            if (String.IsNullOrEmpty(strExpiredDate))
            {
                InvalidFields += "strExpiredDate-";
            }
            if (String.IsNullOrEmpty(strLastIssuedDate))
            {
                InvalidFields += "strLastIssuedDate-";
            }
            if (intCollegeID == -1)
            {
                InvalidFields += "college-";
            }
            if (intFacultyID == -1)
            {
                InvalidFields += "faculty-";
            }


            if (InvalidFields != "")
            {
                return Json(new Result()
                {
                    CodeError = 1,
                    Data = InvalidFields
                }, JsonRequestBehavior.AllowGet);
            }
            else
            if (db.CIR_PATRON.Where(a => a.Code == strCode).Count() > 0)
            {
                return Json(new Result()
                {
                    CodeError = 2,
                    Data = "Bạn đọc với số thẻ " + strCode + " đã tồn tại!"
                }, JsonRequestBehavior.AllowGet);
            }
            else
            {
                string strMiddleName = "";
                if (strFirstName.Split(' ').Length > 1)
                {
                    List<string> names = strFirstName.Split(' ').ToList();
                    string firstName = names.First();
                    names.RemoveAt(0);
                    strMiddleName = string.Join(",", names);
                    strFirstName = firstName;
                }

                var intPatronID = new ObjectParameter("intRetval", typeof(int));
                db.SP_PAT_CREATE_PATRON(
                    strCode, strValidDate, strExpiredDate, strLastIssuedDate, strLastName, strFirstName, strMiddleName, blnSex, strDOB, intEthnicID, intEducationID,
                    intOccupationID, strWorkPlace, strTelephone, strMobile, strEmail, strPortrait, intPatronGroupID, strNote, intIsQue, strIDCard, intPatronID
                    );
                int patronID = (int)intPatronID.Value;
                db.CIR_PATRON.Where(a => a.ID == patronID).First().Password = strCode;
                db.SaveChanges();
                if (strAddress != null && strAddress != "")
                {
                    db.SP_PAT_CREATE_OTHERADDRESS(patronID, strAddress, intProvinceID, strCity, intCountryID, strZip, intisActive);
                }
                if (intCollegeID > 0)
                {
                    db.SP_PAT_CREATE_PATRON_UNIV(patronID, intFacultyID, intCollegeID, strGrade, strClass);
                }
                return Json(new Result()
                {
                    CodeError = 0,
                    Data = strCode
                }, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpPost]
        public JsonResult UploadPhotoPatron()
        {
            string strCode = Request.Form["strCode"];
            if (strCode != null)
            {
                for (int i = 0; i < Request.Files.Count; i++)
                {
                    var file = Request.Files[i];
                    var fileName = strCode + " - " + Path.GetFileName(file.FileName);
                    var path = Path.Combine(Server.MapPath("~/Content/ImagePatron"), fileName);
                    file.SaveAs(path);
                    db.CIR_PATRON.Where(a => a.Code == strCode).First().Portrait = fileName;
                    db.SaveChanges();
                }
            }

            return Json("", JsonRequestBehavior.AllowGet);
        }

        public ActionResult AddPatronByFile()
        {
            return View();
        }

        [HttpPost]
        public ActionResult PreviewPatronFile()
        {
            List<PatronFile> listPatronInFile = new List<PatronFile>();
            List<PatronFile> listPatronInFileInvalid = new List<PatronFile>();
            for (int i = 0; i < Request.Files.Count; i++)
            {
                var file = Request.Files[i];
                var fileName = Path.GetFileName(file.FileName);
                var path = Path.Combine(Server.MapPath("~/Uploads"), fileName);
                file.SaveAs(path);
                
                DataSet ds = new DataSet();
                string ConnectionString = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=" + path + ";Extended Properties=Excel 12.0;";

                using (OleDbConnection conn = new System.Data.OleDb.OleDbConnection(ConnectionString))
                {
                    conn.Open();
                    using (DataTable dtExcelSchema = conn.GetSchema("Tables"))
                    {
                        string sheetName = dtExcelSchema.Rows[0]["TABLE_NAME"].ToString();
                        string query = "SELECT * FROM [" + sheetName + "]";
                        OleDbDataAdapter adapter = new OleDbDataAdapter(query, conn);
                        adapter.Fill(ds, "Items");
                        if (ds.Tables.Count > 0)
                        {
                            if (ds.Tables[0].Rows.Count > 0)
                            {
                                for (int j = 0; j < ds.Tables[0].Rows.Count; j++)
                                {
                                    string DOB;
                                    if (ds.Tables[0].Rows[j].Field<string>("Mã Sinh viên") != null)
                                    {
                                        PatronFile patronFile = new PatronFile();
                                        patronFile.Line = j + 2;
                                        patronFile.strCode = ds.Tables[0].Rows[j].Field<string>("Mã Sinh viên");
                                        patronFile.FullName = ds.Tables[0].Rows[j].Field<string>("Họ và tên");
                                        patronFile.blnSex = ds.Tables[0].Rows[j].Field<string>("Giới tính ");
                                        
                                        patronFile.strEmail = ds.Tables[0].Rows[j].Field<string>("Email");
                                        patronFile.strAddress = ds.Tables[0].Rows[j].Field<string>("Địa chỉ thường trú");
                                        patronFile.Faculty = ds.Tables[0].Rows[j].Field<string>("Chuyên ngành");
                                        patronFile.strMobile = ds.Tables[0].Rows[j].Field<string>("Điện thoại");
                                        patronFile.strGrade = ds.Tables[0].Rows[j].Field<string>("Khoá");
                                        patronFile.College = ds.Tables[0].Rows[j].Field<string>("Trường");
                                        patronFile.strCity = ds.Tables[0].Rows[j].Field<string>("Thành phố");
                                        patronFile.strClass = ds.Tables[0].Rows[j].Field<string>("Lớp");
                                        patronFile.PatronGroup = ds.Tables[0].Rows[j].Field<string>("Nhóm");
                                        try
                                        {
                                            patronFile.strDOB = ds.Tables[0].Rows[j].Field<DateTime>("Ngày sinh");
                                        }
                                        catch (Exception e)
                                        {
                                            DOB = ds.Tables[0].Rows[j].Field<string>("Ngày sinh");
                                            try
                                            {
                                                patronFile.strDOB = Convert.ToDateTime(DOB);
                                            }
                                            catch (Exception)
                                            {
                                                patronFile.IsValid = false;
                                            }
                                            
                                        }
                                        
                                        if (patronFile.IsValid)
                                        {
                                            listPatronInFile.Add(patronFile);
                                        }
                                        else
                                        {
                                            listPatronInFileInvalid.Add(patronFile);
                                        }
                                    }

                                }
                            }
                        }
                    }
                }
            }
            ViewBag.ListPatron = listPatronInFile;
            ViewBag.ListPatronInvalid = listPatronInFileInvalid;
            return View();
        }

        [HttpPost]
        public ActionResult InsertFileToDB()
        {
            List<PatronFile> listPatronInFile =(List<PatronFile>) Session["listPatronInFile"];
            if (listPatronInFile != null)
            {
                foreach (PatronFile p in listPatronInFile)
                {
                    string strLastName = "";
                    string strFirstName = "";
                    if (p.FullName.Split(' ').Length > 1)
                    {
                        List<string> names = p.FullName.Split(' ').ToList();
                        strLastName = names.Last();
                        names.RemoveAt(names.Count - 1);
                        strFirstName = string.Join(" ", names);
                    }
                    int intPatronGroupID = 0;
                    CIR_PATRON_GROUP patronGroup = db.CIR_PATRON_GROUP.Where(a => a.Name.Trim() == p.PatronGroup.Trim()).Count() ==  0 ? 
                        null : db.CIR_PATRON_GROUP.Where(a => a.Name.Trim() == p.PatronGroup.Trim()).First();
                    if (patronGroup != null)
                    {
                        intPatronGroupID = patronGroup.ID;
                    }
                    int intCollegeID = 0;
                    CIR_DIC_COLLEGE college = db.CIR_DIC_COLLEGE.Where(a => a.College.Trim() == p.College.Trim()).Count() == 0 ?
                        null : db.CIR_DIC_COLLEGE.Where(a => a.College.Trim() == p.College.Trim()).First();
                    if (college != null)
                    {
                        intCollegeID = college.ID;
                    }
                    int intFacultyID = 0;
                    CIR_DIC_FACULTY faculty = db.CIR_DIC_FACULTY.Where(a => a.CollegeID == intCollegeID).Where(a => a.Faculty.Trim() == p.Faculty.Trim()).Count() == 0 ? 
                        null : db.CIR_DIC_FACULTY.Where(a => a.CollegeID == intCollegeID).Where(a => a.Faculty.Trim() == p.Faculty.Trim()).First();
                    if (faculty != null)
                    {
                        intFacultyID = faculty.ID;
                    }
                    DateTime strExpiredDate = DateTime.Now;
                    strExpiredDate= strExpiredDate.AddYears(4);
                    NewPatron(p.strCode, DateTime.Now.ToShortDateString(), strExpiredDate.ToShortDateString(), DateTime.Now.ToShortDateString(), strLastName, strFirstName, p.blnSex == "Nam" ? true : false, p.strDOB.ToString(), null, null, null, null, null, p.strMobile
                        , p.strEmail, null, intPatronGroupID, null, 0, null, p.strAddress, 1, p.strCity, 209, "", 0, intCollegeID, intFacultyID, p.strGrade, p.strClass);
                }
                ViewBag.Notify = "Danh sách đã được thêm vào hệ thống!";
            }

            return View();
        }

        [HttpPost]
        public JsonResult AddDictionary(string field, string data, int CollegeID)
        {
            AddDictionaryResult addDictionaryResult = new AddDictionaryResult();
            List<DictionarySelection> list = new List<DictionarySelection>();
            if (field == "intEthnicID")
            {
                db.SP_PAT_CREATE_ETHNIC(data, new ObjectParameter("intOut", typeof(int)));
                addDictionaryResult.Field = "intEthnicID";
                foreach(SP_PAT_GET_ETHNIC_Result r in db.SP_PAT_GET_ETHNIC().ToList())
                {
                    DictionarySelection dictionary = new DictionarySelection();
                    dictionary.ID = r.ID;
                    dictionary.Data = r.Ethnic;
                    list.Add(dictionary);
                }
                addDictionaryResult.ListSelection = list;
                
            }

            if (field == "intOccupationID")
            {
                db.SP_PAT_CREATE_OCCUPATION(data, new ObjectParameter("intOut", typeof(int)));
                addDictionaryResult.Field = "intOccupationID";
                foreach (SP_PAT_GET_OCCUPATION_Result r in db.SP_PAT_GET_OCCUPATION().ToList())
                {
                    DictionarySelection dictionary = new DictionarySelection();
                    dictionary.ID = r.ID;
                    dictionary.Data = r.Occupation;
                    list.Add(dictionary);
                }
                addDictionaryResult.ListSelection = list;
            }

            if (field == "college")
            {
                db.SP_PAT_CREATE_COLLEGE(data, new ObjectParameter("intOut", typeof(int)));
                addDictionaryResult.Field = "college";
                foreach (SP_PAT_GET_COLLEGE_Result r in db.SP_PAT_GET_COLLEGE().ToList())
                {
                    DictionarySelection dictionary = new DictionarySelection();
                    dictionary.ID = r.ID;
                    dictionary.Data = r.College;
                    list.Add(dictionary);
                }
                addDictionaryResult.ListSelection = list;
            }

            if (field == "faculty")
            {
                db.SP_PAT_CREATE_FACULTY(CollegeID ,data, new ObjectParameter("intOut", typeof(int)));
                addDictionaryResult.Field = "faculty";
                foreach (CIR_DIC_FACULTY r in db.CIR_DIC_FACULTY.Where(a => a.CollegeID == CollegeID).ToList())
                {
                    DictionarySelection dictionary = new DictionarySelection();
                    dictionary.ID = r.ID;
                    dictionary.Data = r.Faculty;
                    list.Add(dictionary);
                }
                addDictionaryResult.ListSelection = list;
            }

            if (field == "intProvinceID")
            {
                db.SP_PAT_CREATE_PROVINCE(data, new ObjectParameter("intOut", typeof(int)));
                addDictionaryResult.Field = "intProvinceID";
                foreach (CIR_DIC_PROVINCE r in db.CIR_DIC_PROVINCE.ToList())
                {
                    DictionarySelection dictionary = new DictionarySelection();
                    dictionary.ID = r.ID;
                    dictionary.Data = r.Province;
                    list.Add(dictionary);
                }
                addDictionaryResult.ListSelection = list;
            }

            if (field == "intEducationID")
            {
                db.SP_PAT_CREATE_EDUCATION(data, new ObjectParameter("intOut", typeof(int)));
                addDictionaryResult.Field = "intEducationID";
                foreach (SP_PAT_GET_EDUCATION_Result r in db.SP_PAT_GET_EDUCATION().ToList())
                {
                    DictionarySelection dictionary = new DictionarySelection();
                    dictionary.ID = r.ID;
                    dictionary.Data = r.EducationLevel;
                    list.Add(dictionary);
                }
                addDictionaryResult.ListSelection = list;
            }

            return Json(addDictionaryResult, JsonRequestBehavior.AllowGet);
        } 

        public ActionResult SearchPatron()
        {
            return View();
        }
    }
    class Result
    {
        public int CodeError { get; set; }
        public string Data { get; set; }
    }

    public class PatronFile
    {
        public int Line { get; set; }
        public string strCode { get; set; }
        public string FullName { get; set; }
        public string blnSex { get; set; }
        public DateTime strDOB { get; set; }
        public string strEmail { get; set; }
        public string strAddress { get; set; }
        public string Faculty { get; set; }
        public string strMobile { get; set; }
        public string strGrade { get; set; }
        public string College { get; set; }
        public string strCity { get; set; }
        public string strClass { get; set; }
        public string PatronGroup { get; set; }
        private bool isValid = true;
        public bool IsValid
        {
            get
            {
                
                if (String.IsNullOrEmpty(strCode) ||
                    String.IsNullOrEmpty(FullName) ||
                    String.IsNullOrEmpty(blnSex) ||
                    String.IsNullOrEmpty(strEmail) ||
                    String.IsNullOrEmpty(strAddress) ||
                    String.IsNullOrEmpty(Faculty) ||
                    String.IsNullOrEmpty(strMobile) ||
                    String.IsNullOrEmpty(strGrade) ||
                    String.IsNullOrEmpty(College) ||
                    String.IsNullOrEmpty(strCity) ||
                    String.IsNullOrEmpty(strClass) ||
                    String.IsNullOrEmpty(PatronGroup))
                {
                    isValid = false;
                }

                
                return isValid;
            }
            set
            {
                isValid = value;
            }
            
        }
    }

    public class AddDictionaryResult
    {
        public string Field { get; set; }
        public List<DictionarySelection> ListSelection { get; set; }
    }

    public class DictionarySelection
    {
        public int ID { get; set; }
        public string Data { get; set; }
    }
}
