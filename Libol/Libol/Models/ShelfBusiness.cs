using Libol.EntityResult;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Libol.Models
{
    public class ShelfBusiness
    {
        LibolEntities db = new LibolEntities();
        public List<SP_HOLDING_LIBRARY_SELECT_Result> FPT_SP_HOLDING_LIBRARY_SELECT(int libID, int localLibId, int statusId, int userId, int typeId)
        {
            List<SP_HOLDING_LIBRARY_SELECT_Result> list = db.Database.SqlQuery<SP_HOLDING_LIBRARY_SELECT_Result>("SP_HOLDING_LIBRARY_SELECT {0}, {1}, {2},{3},{4}",
                new object[] { libID, localLibId, statusId, userId, typeId}).ToList();
            return list;
        }
        public List<SP_HOLDING_LOCATION_GET_INFO_Result> FPT_SP_HOLDING_LOCATION_GET_INFO(int libID, int userId, int locId, int statusId)
        {
            List<SP_HOLDING_LOCATION_GET_INFO_Result> list = db.Database.SqlQuery<SP_HOLDING_LOCATION_GET_INFO_Result>("SP_HOLDING_LOCATION_GET_INFO {0}, {1}, {2},{3}",
                new object[] { libID, userId, locId, statusId }).ToList();
            return list;
        }

    }
}