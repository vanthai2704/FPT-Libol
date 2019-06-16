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

        // Modified from store procedure SP_CATA_GET_CATALOGUE_FIELDS
        // data demo GET_CATALOGUE_FIELDS(0, 12, "100$e,010$a,010$b", "", 1);
        public List<GET_CATALOGUE_FIELDS_Result> GET_CATALOGUE_FIELDS(int intIsAuthority, int intFormID, string strFieldCodes, string strAddedFieldCodes, int intGroupBy)
        {
            List<GET_CATALOGUE_FIELDS_Result> list = db.Database.SqlQuery<GET_CATALOGUE_FIELDS_Result>("SP_CATA_GET_CATALOGUE_FIELDS {0}, {1}, {2},{3},{4}",
                new object[] { intIsAuthority, intFormID, strFieldCodes, strAddedFieldCodes, 1 }).ToList();
            return list;
        }

    }
}