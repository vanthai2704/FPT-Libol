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
            //ViewBag.listOverdue = GET_LIST_OVERDUELIST_GETINFOR(43, "", "").ToList();
            return View();
        }

        [HttpPost]
        public PartialViewResult OverdueListResult(Nullable<int> intUserID, string strPatronIDs,string txtSoThe, string txtTenBanDoc, int ddlNhomBanDoc, int ddlTruong, int ddlKhoa, string txtKhoaHoc, string txtLopHoc, int ddlLib, int ddlLoc, string txtTenTaiLieu, string txtSDKCB, DateTime? txtNgayMuonTu, DateTime? txtNgayMuonDen, DateTime? txtNgayTraTu, DateTime? txtNgayTraDen, string txtSoNgayQuaHan, string txtSoNgayQuaHanDen)
        {
            string whereCondition = ProcessCondition( txtSoThe,  txtTenBanDoc,  ddlNhomBanDoc,  ddlTruong,  ddlKhoa,  txtKhoaHoc,  txtLopHoc,  ddlLib,  ddlLoc,  txtTenTaiLieu,  txtSDKCB,  txtNgayMuonTu,  txtNgayMuonDen,  txtNgayTraTu,  txtNgayTraDen,  txtSoNgayQuaHan,  txtSoNgayQuaHanDen);
            ViewBag.listOverdue = GET_LIST_OVERDUELIST_GETINFOR(intUserID, "", whereCondition).ToList();
            return PartialView("_OverdueListResult");
        }

        // trinhlv1
        public List<SP_CIR_OVERDUELIST_GETINFOR_Result> GET_LIST_OVERDUELIST_GETINFOR(Nullable<int> intUserID, string strPatronIDs, string whereCondition)
        {
            List<SP_CIR_OVERDUELIST_GETINFOR_Result> list = db.Database.SqlQuery<SP_CIR_OVERDUELIST_GETINFOR_Result>("SP_CIR_OVERDUELIST_GETINFOR {0}, {1}, {2}",
                new object[] { intUserID, strPatronIDs, whereCondition }).ToList();
            return list;
        }

        private string ProcessCondition(string txtSoThe, string txtTenBanDoc,int ddlNhomBanDoc,int ddlTruong,int ddlKhoa, string txtKhoaHoc, string txtLopHoc,int ddlLib,int ddlLoc, string txtTenTaiLieu, string txtSDKCB, DateTime? txtNgayMuonTu, DateTime? txtNgayMuonDen, DateTime? txtNgayTraTu, DateTime? txtNgayTraDen, string txtSoNgayQuaHan, string txtSoNgayQuaHanDen)
        {
            string str = "";
            if (String.Compare(txtSoThe.Trim(), "", false) != 0)
                str = str + " AND UPPER(A.PatronCode) = '" + txtSoThe.Trim().ToUpper() + "'";
            if (String.Compare(txtTenBanDoc.Trim(), "", false) != 0)
                str = str + " AND UPPER(A.Name) LIKE N'%" + txtTenBanDoc.Trim().ToUpper() + "%'";
            if (ddlNhomBanDoc != -1)
                str = str + " AND A.PatronGroupID = " + ddlNhomBanDoc;
            if (ddlTruong != -1)
                str = str + " AND A.CollegeID = " + ddlTruong;
            if (ddlKhoa != -1)
                str = str + " AND A.FacultyID = " + ddlKhoa;
            if (String.Compare(txtKhoaHoc.Trim(), "", false) != 0)
                str = str + " AND UPPER(A.Grade) LIKE N'%" + txtKhoaHoc.Trim().ToUpper() + "%'";
            if (String.Compare(txtLopHoc.Trim(), "", false) != 0)
                str = str + " AND UPPER(A.Class) LIKE N'%" + txtLopHoc.Trim().ToUpper() + "%'";
            if (ddlLib != -1)
                str = str + " AND A.LibID = " + ddlLib;
            if (ddlLoc != -1)
                str = str + " AND A.LocID = " + ddlLoc;
            if (String.Compare(txtTenTaiLieu.Trim(), "", false) != 0)
                str = str + " AND UPPER(A.MainTitle) LIKE N'%" + txtTenTaiLieu.Trim().ToUpper() + "%'";
            if (String.Compare(txtSDKCB.Trim(), "", false) != 0)
                str = str + " AND UPPER(A.CopyNumber) LIKE '%" + txtSDKCB.Trim().ToUpper() + "%'";
            if (!Equals(txtNgayMuonTu, null))
                str = str + " AND CONVERT(VARCHAR(10), A.CheckOutDate, 112) >= " + txtNgayMuonTu.Value.ToString("yyyyMMdd");
            if (!Equals(txtNgayMuonDen,null))
                str = str + " AND CONVERT(VARCHAR(10), A.CheckOutDate, 112) <= " + txtNgayMuonDen.Value.ToString("yyyyMMdd");
            if (!Equals(txtNgayTraTu, null))
                str = str + " AND CONVERT(VARCHAR(10), A.CheckInDate, 112) >= " + txtNgayTraTu.Value.ToString("yyyyMMdd");
            if (!Equals(txtNgayTraDen, null))
                str = str + " AND CONVERT(VARCHAR(10), A.CheckInDate, 112) <= " + txtNgayTraDen.Value.ToString("yyyyMMdd");
            if (String.Compare(txtSoNgayQuaHan, "", false) != 0)
                str = str + " AND A.OverdueDate >= " + txtSoNgayQuaHan;
            if (String.Compare(txtSoNgayQuaHanDen, "", false) != 0)
                str = str + " AND A.OverdueDate <= " + txtSoNgayQuaHanDen;
            return str;
        }
    }
}