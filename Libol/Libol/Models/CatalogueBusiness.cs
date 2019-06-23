using Libol.EntityResult;
using System;
using System.Collections.Generic;
using System.Data;

using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace Libol.Models
{

    public class CatalogueBusiness
    {
        LibolEntities db = new LibolEntities();

        public CatalogueBusiness()
        {

        }


        public string InsertItem(ITEM item)
        {
            // check FormID,RecordType,... 
            if (!db.MARC_WORKSHEET.Any(m => m.ID == item.FormID)
                || !db.CAT_DIC_RECORDTYPE.Any(m => m.Code == item.RecordType)
                || !db.CAT_DIC_MEDIUM.Any(m => m.ID == item.MediumID)
                || !db.CAT_DIC_ITEM_TYPE.Any(m => m.ID == item.TypeID)
                || !db.CAT_DIC_DIRLEVEL.Any(m => m.Code == item.BibLevel))
            {
                return "";
            }


            int id = db.ITEMs.Select(i => i.ID).Max() + 1;
            // leader 
            string leader = "00000n" + item.RecordType + item.BibLevel + " a22        4500";
            string cataloguer = Convert.ToString(HttpContext.Current.Session["FullName"]);
            // Mã tự tăng
            string sysParam = db.SYS_PARAMETER.Where(s => s.Name.Equals("LIBRARY_ABBREVIATION")).Select(s => s.Val).FirstOrDefault();
            string year = DateTime.Now.Year.ToString();
            year = year.Substring(year.Length - 2);
            db.Database.ExecuteSqlCommand("insert into book_code values(1)");
            string maxIdBookCode = db.Book_code.Select(b => b.ID).Max().ToString().PadLeft(7, '0');
            string code = sysParam + year + maxIdBookCode;

            db.ITEMs.Add(new ITEM()
            {
                AccessLevel = item.AccessLevel,
                BibLevel = item.BibLevel,
                Code = code,
                Leader = leader,
                NewRecord = true,
                MediumID = item.MediumID,
                FormID = item.FormID,
                RecordType = item.RecordType,
                TypeID = item.TypeID,
                CreatedDate = DateTime.Now,
                OPAC = true,
                Cataloguer = cataloguer,
                Reviewer = "",
                CoverPicture = "",
                ID = id

            });
            db.SaveChanges();
            return code;
        }

        public List<GET_CATALOGUE_FIELDS_Result> GetComplatedForm(int intIsAuthority, string strCreator, int SelectedIndex)
        {
            List<FPT_SP_CATA_GETFIELDS_OF_FORM_Result> GetForm = db.FPT_SP_CATA_GETFIELDS_OF_FORM(SelectedIndex, "", 0).ToList();
            string fields = "";
            foreach (FPT_SP_CATA_GETFIELDS_OF_FORM_Result item in GetForm)
            {
                if (item.FieldCode != "001")
                    fields = fields + item.FieldCode + ",";
            }

            List<GET_CATALOGUE_FIELDS_Result> list = GET_CATALOGUE_FIELDS(intIsAuthority, SelectedIndex, fields, "", 0);
            return list;
        }

        public bool CheckExistNumber(string FieldValue, string FieldCode)
        {
            int ItemID = db.CAT_DIC_NUMBER.Where(a => a.Number == FieldValue && a.FieldCode == FieldCode).Select(a => a.ItemID).FirstOrDefault();
            //System.Data.Entity.Core.Objects.ObjectParameter returnID = new System.Data.Entity.Core.Objects.ObjectParameter("lngItemID", typeof (int));
            //var value = db.FPT_SP_CATA_CHECK_EXIST_ITEMNUMBER(FieldValue, FieldCode, returnID);
            if (ItemID > 0)
                return false;
            return true;

        }

        public bool CheckExistTitle(string strTitle, string strItemType)
        {

            //if (ItemID > 0)
            //    return false;
            return true;

        }

        public string InsertOrUpdateFields(List<string> listFieldsName, List<string> listFieldsValue, ITEM item)
        {
            listFieldsName = new List<string>() { "040", "245", "650" };
            listFieldsValue = new List<string>() { "$a Test 1 $b test 1::$a Test 2 $b test 2", "Test", "Test" };
            // Insert
            if (String.IsNullOrEmpty(item.Code))
            {
                if (listFieldsValue.Count > 0 && listFieldsName.Count > 0)
                {
                    // check trường 245 ISBN


                    // insert item -- Moc data
                    item.FormID = 13;
                    item.MediumID = 3;
                    item.RecordType = "c";
                    item.TypeID = 1;
                    item.BibLevel = "m";
                    InsertItem(item);

                    //add content vào các bảng Fields
                    for (int i = 0; i < listFieldsName.Count; i++)
                    {
                        string fieldName = "FIELD" + listFieldsName[i].Substring(0, 1) + "00s";
                        if (listFieldsValue[i].Contains("::"))
                        {
                            string[] arr = listFieldsValue[i].Split(new[] { "::" }, StringSplitOptions.None);
                            for (int j = 0; j < arr.Length; j++)
                            {
                                db.Database.ExecuteSqlCommand("INSERT INTO " + fieldName + " (ItemID, FieldCode, Content, Ind1, Ind2) VALUES (" + item.ID + ",'" + item.Code + "','" + arr[j] + "','" + "" + "','" + "'" + ")");
                            }
                        }
                        else
                        db.Database.ExecuteSqlCommand("INSERT INTO " + fieldName + " (ItemID, FieldCode, Content, Ind1, Ind2) VALUES (" + item.ID + ",'" + item.Code + "','" + listFieldsValue[i] + "','" + "" + "','" + "'" + ")");


                    }
                }

            }
            // Update
            else
            {

            }


            return "";
        }

        public List<GET_CATALOGUE_FIELDS_Result> GET_CATALOGUE_FIELDS(int intIsAuthority, int intFormID, string strFieldCodes, string strAddedFieldCodes, int intGroupBy)
        {
            List<GET_CATALOGUE_FIELDS_Result> list = db.Database.SqlQuery<GET_CATALOGUE_FIELDS_Result>("SP_CATA_GET_CATALOGUE_FIELDS {0}, {1}, {2},{3},{4}",
                new object[] { intIsAuthority, intFormID, strFieldCodes, strAddedFieldCodes, 1 }).ToList();
            return list;
        }
    }
}