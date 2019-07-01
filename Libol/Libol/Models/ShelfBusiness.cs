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

        public string GenCopyNumber(int locId)
        {
            string symbol = "";
            int maxNumber = 0;
            List<SP_HOLDING_LOCATION_GET_INFO_Result> list = FPT_SP_HOLDING_LOCATION_GET_INFO(0,0,locId,-1);
            if (list.Count()>0)
            {
                symbol = list[0].Symbol;
                maxNumber = Convert.ToInt32(list[0].MaxNumber) + 1;
            }else
            {
                return "Kho không tồn tại";
            }

            int length = 6 - maxNumber.ToString().Length;
            string stringZero = "";
            for (int i = 0; i < length; i++)
            {
                stringZero = stringZero + "0";
            }
            string copyNumber = symbol + stringZero + maxNumber;
            return copyNumber;
        }

        public List<HOLDING> InsertHolding(HOLDING holding,int numberOfCN)
        {
            List<HOLDING> holdings = new List<HOLDING>();
            ITEM item =  db.ITEMs.Where( i=> i.ID == holding.ItemID).FirstOrDefault();
            for (int i=0;i<numberOfCN;i++)
            {
                string copyNumber = GenCopyNumber(holding.LocationID);
                
                // procedure đã + 1 giá trị MaxNumber trong HOLDING_LOCATION
                db.SP_HOLDING_INS(
                    holding.ItemID,
                    holding.LocationID,
                    holding.LibID,
                    holding.UseCount,
                    holding.Volume,
                    // ngày bổ sung
                    holding.AcquiredDate.ToString(),
                    copyNumber,
                    holding.InUsed == true ? 1 : 0,
                    holding.InCirculation == true ? 1 : 0,
                    holding.ILLID,
                    holding.Price,
                    // giá sách
                    holding.Shelf,
                    holding.POID,
                    //ngày sử dụng cuối
                    holding.DateLastUsed.ToString(),
                    item.CallNumber,
                    holding.Acquired == true ? 1 : 0,
                    holding.Note,
                    holding.LoanTypeID,
                    holding.AcquiredSourceID,
                    holding.Currency,
                    holding.Rate,
                    // số chứng từ
                    holding.RecordNumber,
                    // ngày chứng từ
                    holding.ReceiptedDate.ToString()
                    );
                holding.CopyNumber = copyNumber;
                holdings.Add(holding);
            }
            return holdings;
        } 


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