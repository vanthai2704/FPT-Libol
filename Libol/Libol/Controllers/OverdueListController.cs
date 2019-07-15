using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.EntityResult;
using Libol.Models;

namespace Libol.Controllers
{
    public class OverdueListController : Controller
    {
        private LibolEntities db = new LibolEntities();
        // GET: OverdueList
        public ActionResult OverdueList()
        {
            ViewBag.listOverdue = GET_LIST_OVERDUELIST_GETINFOR(43, "", "").ToList();
            return View();
        }

        // trinhlv1
        public List<SP_CIR_OVERDUELIST_GETINFOR_Result> GET_LIST_OVERDUELIST_GETINFOR(Nullable<int> intUserID, string strPatronIDs, string whereCondition)
        {
            List<SP_CIR_OVERDUELIST_GETINFOR_Result> list = db.Database.SqlQuery<SP_CIR_OVERDUELIST_GETINFOR_Result>("SP_CIR_OVERDUELIST_GETINFOR {0}, {1}, {2}",
                new object[] { intUserID, strPatronIDs, whereCondition }).ToList();
            return list;
        }

        //private string ProcessCondition(string txtSoThe,string txtTenBanDoc,string txtKhoaHoc,string txtLopHoc,string txtTenTaiLieu, string txtSDKCB,DateTime txtNgayMuonTu, DateTime txtNgayMuonDen,DateTime txtNgayTraTu, DateTime txtNgayTraDen,int txtSoNgayQuaHan,int txtSoNgayQuaHanDen)
        //{
        //    string str = "";
        //    if (String.Compare(txtSoThe.Trim(), "", false) != 0)
        //        str = str + " AND UPPER(A.PatronCode) = '" + txtSoThe.Trim().ToUpper() + "'";
        //    if (String.Compare(txtTenBanDoc.Trim(), "", false) != 0)
        //        str = str + " AND UPPER(A.Name) LIKE N'%" + txtTenBanDoc.Trim().ToUpper() + "%'";
        //    if (this.ddlNhomBanDoc.SelectedIndex > 0)
        //        str = str + " AND A.PatronGroupID = " + StringType.FromInteger(Convert.ToInt32(this.ddlNhomBanDoc.SelectedValue));
        //    if (this.ddlTruong.SelectedIndex > 0)
        //        str = str + " AND A.CollegeID = " + StringType.FromInteger(Convert.ToInt32(this.ddlTruong.SelectedValue));
        //    if (this.ddlKhoa.SelectedIndex > 0)
        //        str = str + " AND A.FacultyID = " + StringType.FromInteger(Convert.ToInt32(this.ddlKhoa.SelectedValue));
        //    if (String.Compare(txtKhoaHoc.Trim(), "", false) != 0)
        //        str = str + " AND UPPER(A.Grade) LIKE N'%" + txtKhoaHoc.Trim().ToUpper() + "%'";
        //    if (String.Compare(txtLopHoc.Trim(), "", false) != 0)
        //        str = str + " AND UPPER(A.Class) LIKE N'%" + txtLopHoc.Trim().ToUpper() + "%'";
        //    if (this.ddlLib.SelectedIndex > 0)
        //        str = str + " AND A.LibID = " + StringType.FromInteger(Convert.ToInt32(this.ddlLib.SelectedValue));
        //    if (this.ddlLoc.SelectedIndex > 0)
        //        str = str + " AND A.LocID = " + StringType.FromInteger(Convert.ToInt32(this.ddlLoc.SelectedValue));
        //    if (String.Compare(txtTenTaiLieu.Trim(), "", false) != 0)
        //        str = str + " AND UPPER(A.MainTitle) LIKE N'%" + txtTenTaiLieu.Trim().ToUpper() + "%'";
        //    if (String.Compare(txtSDKCB.Trim(), "", false) != 0)
        //        str = str + " AND UPPER(A.CopyNumber) LIKE '%" + txtSDKCB.Trim().ToUpper() + "%'";
        //    if (String.Compare(txtNgayMuonTu.ToString("yyyyMMdd"), "", false) != 0)
        //        str = str + " AND CONVERT(VARCHAR(10), A.CheckOutDate, 112) >= " + txtNgayMuonTu.ToString("yyyyMMdd");
        //    if (String.Compare(txtNgayMuonDen.ToString("yyyyMMdd"), "", false) != 0)
        //        str = str + " AND CONVERT(VARCHAR(10), A.CheckOutDate, 112) <= " + txtNgayMuonDen.ToString("yyyyMMdd");
        //    if (String.Compare(txtNgayTraTu.ToString("yyyyMMdd"), "", false) != 0)
        //        str = str + " AND CONVERT(VARCHAR(10), A.CheckInDate, 112) >= " + txtNgayTraTu.ToString("yyyyMMdd");
        //    if (String.Compare(txtNgayTraDen.ToString("yyyyMMdd"), "", false) != 0)
        //        str = str + " AND CONVERT(VARCHAR(10), A.CheckInDate, 112) <= " + txtNgayTraDen.ToString("yyyyMMdd");
        //    if (String.Compare(txtSoNgayQuaHan.ToString(), "", false) != 0)
        //        str = str + " AND A.OverdueDate >= " +txtSoNgayQuaHan;
        //    if (String.Compare(txtSoNgayQuaHanDen.ToString(), "", false) != 0)
        //        str = str + " AND A.OverdueDate <= " + txtSoNgayQuaHanDen;
        //    return str;
        //}
    }
}