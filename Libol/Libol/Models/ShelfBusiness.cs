using Libol.Controllers;
using Libol.EntityResult;
using System;
using System.Collections.Generic;
using System.Data.Entity.Core.Objects;
using System.Data.Entity.Validation;
using System.Linq;
using System.Web;

namespace Libol.Models
{
    public class ShelfBusiness
    {
        LibolEntities db = new LibolEntities();
        public bool IsExistHolding(string strCN, int intLocationID, int intCopyID = -1)
        {
            List<string> list = db.SP_CHECK_COPYNUMBER(strCN, intCopyID , intLocationID).ToList();
            return list.Count > 0 ? true : false;

        }
        public string GenCopyNumber(int locId)
        {
            string symbol = "";
            int maxNumber = 0;
            List<SP_HOLDING_LOCATION_GET_INFO_Result> list = FPT_SP_HOLDING_LOCATION_GET_INFO(0, 0, locId, -1);
            if (list != null && list.Count() > 0)
            {
                symbol = list[0].Symbol;
                maxNumber = Convert.ToInt32(list[0].MaxNumber) + 1;
            }
            else
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

        public string InsertHolding(HOLDING holding, int numberOfCN)
        {

            if (String.IsNullOrEmpty(holding.CopyNumber))
            {
                return "Hãy tạo đăng ký cá biệt";
            }

            List<HOLDING> holdings = new List<HOLDING>();
            //   ITEM item = db.ITEMs.Where(i => i.ID == holding.ItemID).FirstOrDefault();
            holding.Volume = "";
            holding.UseCount = 0;
            holding.InUsed = false;
            holding.InCirculation = false;
            holding.ILLID = 0;
            holding.DateLastUsed = DateTime.Now;
            //db.ITEMs.Where(i => i.ID == holding.ItemID).FirstOrDefault().CallNumber.ToString()
            holding.CallNumber = null;
            holding.Acquired = false;
            holding.Note = "";
            holding.POID = 0;


            // check start holding tồn tại chưa

            if (!IsExistHolding(holding.CopyNumber, holding.LocationID, -1))
            {

                string symbol = holding.CopyNumber.Substring(0, holding.CopyNumber.Length - 6);
                string strNumber = holding.CopyNumber.Substring(symbol.Length, 6);
                int number = Convert.ToInt32(strNumber);

                for (int i = 0; i < numberOfCN; i++)
                {
                    // tạo list ĐKCB
                    int length = 6 - number.ToString().Length;
                    string stringZero = "";
                    for (int j = 0; j < length; j++)
                    {
                        stringZero = stringZero + "0";
                    }
                    string copyNumber = symbol + stringZero + number;
                    number++;
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
                        holding.CallNumber,
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
            }
            else
            {
                return "ĐKCB đã tồn tại hãy sinh giá trị mới";
            }
            return "";
        }

        public string UpdateHolding(HoldingTable holding)
        {
           var currentHolding= db.HOLDINGs.Where(h=>h.ID == holding.ID).Single();
            //currentHolding.ID = holding.ID;
            //currentHolding.InCirculation = holding.InCirculation;
            //currentHolding.InUsed = holding.InUsed;
            //currentHolding.IsConfusion = holding.IsConfusion;
            //currentHolding.IsLost = holding.IsLost;
            //currentHolding.ItemID = holding.ItemID;
            //currentHolding.LibID = holding.LibID;
            //currentHolding.LoanTypeID = holding.LoanTypeID;
            //currentHolding.LocationID = holding.LocationID;
            //currentHolding.LockedReason = holding.LockedReason;
            currentHolding.Note = holding.Note;
          //  currentHolding.OnHold = holding.OnHold;
           // currentHolding.POID = holding.POID;
            currentHolding.Price = holding.Price;
            currentHolding.Rate = db.ACQ_CURRENCY.Where( c=>c.CurrencyCode == holding.Currency).Select( d=>d.Rate).Single();
          //  currentHolding.Reason = holding.Reason;
            currentHolding.ReceiptedDate = DateTime.ParseExact(holding.ReceiptedDate,"dd/MM/yyyy",null) ;
            currentHolding.RecordNumber = holding.RecordNumber;
            currentHolding.Shelf = holding.Shelf;
         //   currentHolding.UseCount = holding.UseCount;
            currentHolding.Volume = holding.Volume;
         //   currentHolding.ILLID = holding.ILLID;
          //  currentHolding.DateLastUsed = DateTime.ParseExact(holding.Date, "dd/MM/yyyy", null);
            currentHolding.Currency = holding.Currency;
          //  currentHolding.CopyNumber = holding.CopyNumber;
            currentHolding.CallNumber = holding.CallNumber;
           // currentHolding.Availlable = holding.Availlable;
          //  currentHolding.AcquiredSourceID = holding.AcquiredSourceID;
            currentHolding.AcquiredDate = DateTime.ParseExact(holding.AcquiredDate, "dd/MM/yyyy", null);
            //   currentHolding.Acquired = holding.Acquired;
            try
            {
                // Your code...
                // Could also be before try if you know the exception occurs in SaveChanges

                db.SaveChanges();
            }
            catch (DbEntityValidationException e)
            {
                foreach (var eve in e.EntityValidationErrors)
                {
                    Console.WriteLine("Entity of type \"{0}\" in state \"{1}\" has the following validation errors:",
                        eve.Entry.Entity.GetType().Name, eve.Entry.State);
                    foreach (var ve in eve.ValidationErrors)
                    {
                        Console.WriteLine("- Property: \"{0}\", Error: \"{1}\"",
                            ve.PropertyName, ve.ErrorMessage);
                    }
                }
                throw;
            }
       
            return "Cập nhật thành công!";
        }

        public string GetHoldingStatus(bool InUsed, bool InCirculation,bool Acquired)
        {

            string inUsed = InUsed ? "1" : "0";
            string inCirculation = InCirculation ? "1" : "0";
            string acquired = Acquired ? "1" : "0";
            string InUsed_InCirculation_Acquired = inUsed + inCirculation + acquired;
            switch (InUsed_InCirculation_Acquired) {
                case "011": return "<p style='color: #28a745'>Lưu thông<p>";
                case "001": return "Khóa";
                case "010": return "<p style='color: #dc3545'>Chưa kiểm nhận<p>";
                case "111": return "<p style='color: #ffc107'>Đang cho mượn<p>";
                case "110": return "<p style='color: #dc3545'>Chưa kiểm nhận<p>";
                case "000": return "<p style='color: #dc3545'>Chưa kiểm nhận<p>";
                case "101": return "<p style='color: #dc3545'>Khóa<p>";
                case "100": return "<p style='color: #dc3545'>Chưa kiểm nhận<p>";
                default: return "";
            }
        }


        public List<SP_HOLDING_LIBRARY_SELECT_Result> FPT_SP_HOLDING_LIBRARY_SELECT(int libID, int localLibId, int statusId, int userId, int typeId)
        {
            List<SP_HOLDING_LIBRARY_SELECT_Result> list = db.Database.SqlQuery<SP_HOLDING_LIBRARY_SELECT_Result>("SP_HOLDING_LIBRARY_SELECT {0}, {1}, {2},{3},{4}",
                new object[] { libID, localLibId, statusId, userId, typeId }).ToList();
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