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


        public string InsertItem(int formId, string dirCode, int mediumId, string recordTypeCode, int itemTypeId, byte accessLevel, string cataloguer)
        {
            int id = db.ITEMs.Select(i => i.ID).Max() + 1;
            // leader 
            string leader = "00000n" + recordTypeCode + dirCode + " a22        4500";

            // Mã tự tăng
            string sysParam = db.SYS_PARAMETER.Where(s => s.Name.Equals("LIBRARY_ABBREVIATION")).Select(s => s.Val).FirstOrDefault();
            string year = DateTime.Now.Year.ToString();
            year = year.Substring(year.Length - 2);
            db.Database.ExecuteSqlCommand("insert into book_code values(1)");
            string maxIdBookCode = db.Book_code.Select(b => b.ID).Max().ToString().PadLeft(7, '0');
            string code = sysParam + year + maxIdBookCode;

            db.ITEMs.Add(new ITEM()
            {
                AccessLevel = accessLevel,
                BibLevel = dirCode,
                Code = code,
                Leader = leader,
                NewRecord = true,
                MediumID = mediumId,
                FormID = formId,
                RecordType = recordTypeCode,
                TypeID = itemTypeId,
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

        public List<GET_CATALOGUE_FIELDS_Result> GET_CATALOGUE_FIELDS(int intIsAuthority, int intFormID, string strFieldCodes, string strAddedFieldCodes, int intGroupBy)
        {
            List<GET_CATALOGUE_FIELDS_Result> list = db.Database.SqlQuery<GET_CATALOGUE_FIELDS_Result>("SP_CATA_GET_CATALOGUE_FIELDS {0}, {1}, {2},{3},{4}",
                new object[] { intIsAuthority, intFormID, strFieldCodes, strAddedFieldCodes, 1 }).ToList();
            return list;
        }
    }
}