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
        public void InsertItem(int formId, string dirCode, int mediumId, string recordTypeCode, int itemTypeId, byte accessLevel, string cataloguer)
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
        }


    }
}