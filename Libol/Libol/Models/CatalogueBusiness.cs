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


        public string InsertItem(ref ITEM item)
        {
           int formId = item.FormID;
            string recordType = item.RecordType;
            int mediumId = item.MediumID;
            int typeId = item.TypeID;
            string bibLevel = item.BibLevel;

            // check FormID,RecordType,... 
            if (!db.MARC_WORKSHEET.Any(m => m.ID == formId)
                || !db.CAT_DIC_RECORDTYPE.Any(m => m.Code == recordType)
                || !db.CAT_DIC_MEDIUM.Any(m => m.ID == mediumId)
                || !db.CAT_DIC_ITEM_TYPE.Any(m => m.ID == typeId)
                || !db.CAT_DIC_DIRLEVEL.Any(m => m.Code == bibLevel))
            {
                return "";
            }


            int id = db.ITEMs.Select(i => i.ID).Max() + 1;
            // leader 
            string leader = "00025n" + item.RecordType + item.BibLevel + " a22        4500";
            string cataloguer = Convert.ToString(HttpContext.Current.Session["FullName"]);
            // Mã tự tăng
            string sysParam = db.SYS_PARAMETER.Where(s => s.Name.Equals("LIBRARY_ABBREVIATION")).Select(s => s.Val).FirstOrDefault();
            string year = DateTime.Now.Year.ToString();
            year = year.Substring(year.Length - 2);
            db.Database.ExecuteSqlCommand("insert into book_code values(1)");
            string maxIdBookCode = db.Book_code.Select(b => b.ID).Max().ToString().PadLeft(7, '0');
            string code = sysParam + year + maxIdBookCode;
            ITEM newItem = new ITEM()
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

            };
            db.ITEMs.Add(newItem);
            db.SaveChanges();
            item = newItem;
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

        public List<GET_CATALOGUE_FIELDS_Result> GetComplatedFormForDetail(int intIsAuthority, string strCreator, int SelectedIndex)
        {
            List<FPT_SP_CATA_GETFIELDS_OF_FORM_Result> GetForm = db.FPT_SP_CATA_GETFIELDS_OF_FORM(SelectedIndex, "", 0).ToList();
            string fields = "";
            foreach (FPT_SP_CATA_GETFIELDS_OF_FORM_Result item in GetForm)
            {
                if (item.FieldCode != "001")
                    fields = fields + item.FieldCode.Substring( 0 , 3 ) + ",";
            }

            List<GET_CATALOGUE_FIELDS_Result> list = GET_CATALOGUE_FIELDS(intIsAuthority, SelectedIndex, fields, "", 0);
            return list;
        }

        public bool CheckExistNumber(string FieldValue , string FieldCode )
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

        public string InsertOrUpdateFields(List<string> listFieldsName, List<string> listFieldsValue)
        {
            //listFieldsName = new List<string>() { "040", "245", "650" };
            //listFieldsValue = new List<string>() { "$a Test 1 $b test 1::$a Test 2 $b test 2", "Test", "Test" };
            // Insert


            // lấy ra code của item
            string code = listFieldsValue[listFieldsName.IndexOf("001")];


            if (String.IsNullOrEmpty(code))
            {
                if (listFieldsValue.Count > 0 && listFieldsName.Count > 0)
                {
                    // check trường 245 ISBN
                    listFieldsValue.RemoveAt(listFieldsName.IndexOf("001"));
                    listFieldsName.RemoveAt(listFieldsName.IndexOf("001"));
                    

                    byte accessLevel =0;
                    int typeId = 1, mediumId = 3, formId = 13;
                    string coverPicture="", bibLevel="", recordType="";
                    // insert item 
                   if (listFieldsName.Contains("926"))
                    {
                        int index = listFieldsName.IndexOf("926");
                        accessLevel = Convert.ToByte(listFieldsValue[index]);
                        listFieldsName.RemoveAt(index);
                        listFieldsValue.RemoveAt(index);
                    }
                    if (listFieldsName.Contains("927"))
                    {
                        int index = listFieldsName.IndexOf("927");
                        typeId = Convert.ToInt32(listFieldsValue[listFieldsName.IndexOf("927")]);
                        listFieldsName.RemoveAt(index);
                        listFieldsValue.RemoveAt(index);
                    }
                        
                    if (listFieldsName.Contains("907"))
                    {
                        int index = listFieldsName.IndexOf("907");
                        coverPicture = listFieldsValue[listFieldsName.IndexOf("907")];
                        listFieldsName.RemoveAt(index);
                        listFieldsValue.RemoveAt(index);
                    }
                   
                    if (listFieldsName.Contains("DirLevel"))
                    {
                        int index = listFieldsName.IndexOf("DirLevel");
                        bibLevel = listFieldsValue[listFieldsName.IndexOf("DirLevel")];
                        listFieldsName.RemoveAt(index);
                        listFieldsValue.RemoveAt(index);
                    }
                    if (listFieldsName.Contains("RecordType"))
                    {
                        int index = listFieldsName.IndexOf("RecordType");
                        recordType = listFieldsValue[listFieldsName.IndexOf("RecordType")];
                        listFieldsName.RemoveAt(index);
                        listFieldsValue.RemoveAt(index);
                    }
                    if (listFieldsName.Contains("925"))
                    {
                        int index = listFieldsName.IndexOf("925");
                        mediumId = Convert.ToInt32(listFieldsValue[listFieldsName.IndexOf("925")]);
                        listFieldsName.RemoveAt(index);
                        listFieldsValue.RemoveAt(index);
                    }
                    if (listFieldsName.Contains("FormId"))
                    {
                        int index = listFieldsName.IndexOf("FormId");
                        formId = Convert.ToInt32(listFieldsValue[listFieldsName.IndexOf("FormId")]);
                        listFieldsName.RemoveAt(index);
                        listFieldsValue.RemoveAt(index);
                    }
                  
                    ITEM item = new ITEM()
                    {
                        AccessLevel = accessLevel,
                        MediumID = mediumId,
                        TypeID = typeId,
                        CoverPicture = coverPicture,
                        FormID = formId,
                        RecordType = recordType,
                        BibLevel = bibLevel
                    };
                    InsertItem(ref item);

                    //add content vào các bảng Fields
                    for (int i = 0; i < listFieldsName.Count; i++)
                    {
                        string fieldName = "FIELD" + listFieldsName[i].Substring(0, 1) + "00s";
                        if (!String.IsNullOrEmpty(listFieldsValue[i]) && listFieldsValue[i].Contains("::"))
                        {
                            string[] arr = listFieldsValue[i].Split(new[] { "::" }, StringSplitOptions.None);
                            for (int j = 0; j < arr.Length; j++)
                            {
                                db.Database.ExecuteSqlCommand("INSERT INTO " + fieldName + " (ItemID, FieldCode, Content, Ind1, Ind2) VALUES (" + item.ID + ",'" + listFieldsName[i] + "','" + arr[j] + "','" + "" + "','" + "'" + ")");
                            }
                        }
                        else
                        db.Database.ExecuteSqlCommand("INSERT INTO " + fieldName + " (ItemID, FieldCode, Content, Ind1, Ind2) VALUES (" + item.ID + ",'" + listFieldsName[i] + "','" +""+ listFieldsValue[i] + "','" + "" + "','" + "'" + ")");


                    }
                }

            }
            // Update
            else
            {

            }


            return "";
        }


        public void HandleListFields(List<string> listFieldName, List<string> listFieldValue)
        {
            List<string> listFieldNameOutput = new List<string>();
            List<string> listFieldValueOutput = new List<string>();
            if (listFieldName.Count > 0 && listFieldValue.Count > 0)
            {
                string outputValue245 = "";
                string outputValue300 = "";
                string outputValue260 = "";
                string outputValue090 = "";
                bool flag245 = false;
                bool flag300 = false;
                bool flag260 = false;
                bool flag090 = false;

                for (int i = 0; i < listFieldName.Count; i++)
                {
                    bool checkInput = !String.IsNullOrEmpty(listFieldValue[i]);

                    if (listFieldName[i].Equals("001") && checkInput)
                    {
                        // nothing
                    }

                    if ((listFieldName[i].Equals("020$a") && checkInput) || (listFieldName[i].Equals("022$a") && checkInput))
                    {
                        listFieldValue[i] = "$a" + listFieldValue[i];
                        listFieldName[i] = listFieldName[i].Substring(0, 3);
                    }
                    if ((listFieldName[i].Equals("040$a") && checkInput) || (listFieldName[i].Equals("041$a") && checkInput) || (listFieldName[i].Equals("044$a") && checkInput) || (listFieldName[i].Equals("082$a") && checkInput))
                    {
                        listFieldValue[i] = "$a" + listFieldValue[i];
                        listFieldName[i] = listFieldName[i].Substring(0, 3);
                    }
                    if ((listFieldName[i].Equals("100$a") && checkInput) || (listFieldName[i].Equals("110$a") && checkInput))
                    {
                        listFieldValue[i] = "$a" + listFieldValue[i];
                        listFieldName[i] = listFieldName[i].Substring(0, 3);
                    }
                    if ((listFieldName[i].Equals("250$a") && checkInput) || (listFieldName[i].Equals("246$a") && checkInput))
                    {
                        listFieldValue[i] = "$a" + listFieldValue[i];
                        listFieldName[i] = listFieldName[i].Substring(0, 3);
                    }
                    if ((listFieldName[i].Equals("490$a") && checkInput) || (listFieldName[i].Equals("500$a") && checkInput) || (listFieldName[i].Equals("520$a") && checkInput))
                    {
                        listFieldValue[i] = "$a" + listFieldValue[i];
                        listFieldName[i] = listFieldName[i].Substring(0, 3);
                    }
                    if ((listFieldName[i].Equals("650$a") && checkInput) || (listFieldName[i].Equals("653$a") && checkInput) || (listFieldName[i].Equals("700$a") && checkInput))
                    {
                        listFieldValue[i] = "$a" + listFieldValue[i];
                        listFieldName[i] = listFieldName[i].Substring(0, 3);
                    }
                    if ((listFieldName[i].Equals("852$a") && checkInput) || (listFieldName[i].Equals("900$a") && checkInput) || (listFieldName[i].Equals("911$a") && checkInput) || (listFieldName[i].Equals("925$a") && checkInput) || (listFieldName[i].Equals("926$a") && checkInput) || (listFieldName[i].Equals("927$a") && checkInput))
                    {
                        listFieldValue[i] = "$a" + listFieldValue[i];
                        listFieldName[i] = listFieldName[i].Substring(0, 3);
                    }

                    string nameTmp = listFieldName[i];
                    string valueTmp = listFieldValue[i];
                    if ("090".Equals(nameTmp.Substring(0, 3)) && checkInput)
                    {
                        if (listFieldName[i].Equals("090$a") && checkInput)
                        {
                            valueTmp = "$a" + valueTmp;
                        }
                        if (listFieldName[i].Equals("090$b") && checkInput)
                        {
                            valueTmp = "$b" + valueTmp;
                        }
                        flag090 = true;
                        outputValue090 = outputValue090 + valueTmp;
                        continue;
                    }
                    if (flag090)
                    {
                        listFieldValueOutput.Add(outputValue090);
                        listFieldNameOutput.Add("090");
                        flag090 = false;
                    }
                    if ("245".Equals(nameTmp.Substring(0, 3)) && checkInput)
                    {

                        if (listFieldName[i].Equals("245$a") && checkInput)
                        {
                            valueTmp = "$a" + valueTmp;
                        }
                        if (listFieldName[i].Equals("245$b1") && checkInput)
                        {

                            valueTmp = "=$b" + valueTmp;
                            if (valueTmp.Contains("//"))
                            {
                                valueTmp = valueTmp.Replace("//", "=$b");
                            }
                        }
                        if (listFieldName[i].Equals("245$b2") && checkInput)
                        {
                            valueTmp = ":$b" + valueTmp;
                            if (valueTmp.Contains("//"))
                            {
                                valueTmp = valueTmp.Replace("//", ":$b");
                            }
                        }
                        if (listFieldName[i].Equals("245$c") && checkInput)
                        {
                            valueTmp = "/$c" + valueTmp;
                        }
                        if (listFieldName[i].Equals("245$n") && checkInput)
                        {
                            valueTmp = ".$n" + valueTmp;
                        }
                        if (listFieldName[i].Equals("245$p") && checkInput)
                        {
                            valueTmp = ":$p" + valueTmp;
                        }
                        flag245 = true;
                        outputValue245 = outputValue245 + valueTmp;
                        continue;
                    }
                    if (flag245)
                    {
                        listFieldValueOutput.Add(outputValue245);
                        listFieldNameOutput.Add("245");
                        flag245 = false;
                    }

                    if ("300".Equals(nameTmp.Substring(0, 3)) && checkInput)
                    {
                        if (listFieldName[i].Equals("300$a") && checkInput)
                        {
                            valueTmp = "$a" + listFieldValue[i];
                        }
                        if (listFieldName[i].Equals("300$b") && checkInput)
                        {
                            valueTmp = ":$b" + listFieldValue[i];
                        }
                        if (listFieldName[i].Equals("300$c") && checkInput)
                        {
                            valueTmp = ";$c" + listFieldValue[i];
                        }
                        if (listFieldName[i].Equals("300$e") && checkInput)
                        {
                            valueTmp = "+$e" + listFieldValue[i];
                        }
                        flag300 = true;
                        outputValue300 = outputValue300 + valueTmp;
                        continue;

                    }
                    if (flag300)
                    {
                        listFieldValueOutput.Add(outputValue300);
                        listFieldNameOutput.Add("300");
                        flag300 = false;
                    }

                    if ("260".Equals(nameTmp.Substring(0, 3)) && checkInput)
                    {
                        if (listFieldName[i].Equals("260$a") && checkInput)
                        {
                            valueTmp = "$a" + valueTmp;
                        }
                        if (listFieldName[i].Equals("260$b") && checkInput)
                        {
                            valueTmp = ":$b" + valueTmp;
                        }
                        if (listFieldName[i].Equals("260$c") && checkInput)
                        {
                            valueTmp = ",$c" + valueTmp;
                        }
                        flag260 = true;
                        outputValue260 = outputValue260 + valueTmp;
                        continue;

                    }
                    if (flag260)
                    {
                        listFieldValueOutput.Add(outputValue260);
                        listFieldNameOutput.Add("260");
                        flag260 = false;
                    }

                    //if (String.IsNullOrEmpty(nameTmp))
                    if (!String.IsNullOrEmpty(valueTmp) || nameTmp.Equals("001"))
                    {
                        listFieldNameOutput.Add(nameTmp);
                        listFieldValueOutput.Add(valueTmp);
                       
                    }
                    else
                    {
                        listFieldNameOutput.Remove(nameTmp);
                        listFieldValueOutput.Remove(valueTmp);
                    }


                }
            }
            InsertOrUpdateFields(listFieldNameOutput, listFieldValueOutput);

        }

        public List<GET_CATALOGUE_FIELDS_Result> GET_CATALOGUE_FIELDS(int intIsAuthority, int intFormID, string strFieldCodes, string strAddedFieldCodes, int intGroupBy)
        {
            List<GET_CATALOGUE_FIELDS_Result> list = db.Database.SqlQuery<GET_CATALOGUE_FIELDS_Result>("SP_CATA_GET_CATALOGUE_FIELDS {0}, {1}, {2},{3},{4}",
                new object[] { intIsAuthority, intFormID, strFieldCodes, strAddedFieldCodes, 0 }).ToList();
            return list;
        }
    }
}