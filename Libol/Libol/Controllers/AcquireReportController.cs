﻿using Libol.Models;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Web.Mvc;

namespace Libol.Controllers
{
    public class AcquireReportController : BaseController
    {
        LibolEntities le = new LibolEntities();
        AcquisitionBusiness ab = new AcquisitionBusiness();
        List<Temper> listTempt = new List<Temper>();
        int UserID = 49;
        public string GetContent(string copynumber)
        {
            string validate = copynumber.Replace("$a", " ");
            validate = validate.Replace("$b", " ");
            validate = validate.Replace("$c", " ");
            validate = validate.Replace("$n", " ");
            validate = validate.Replace("$p", " ");
            validate = validate.Replace("$e", " ");

            return validate.Trim();
        }
        public ActionResult AcquisitionIndex()
        {
            return View();
        }
        // GET: AcquireReport
        public ActionResult Index()
        {
            List<SelectListItem> lib = new List<SelectListItem>();
            lib.Add(new SelectListItem { Text = "Hãy chọn thư viện", Value = "" });
            foreach (var l in le.SP_HOLDING_LIB_SEL(UserID).ToList())
            {
                lib.Add(new SelectListItem { Text = l.Code, Value = l.ID.ToString() });
            }
            ViewData["lib"] = lib;
            //String s = "";
            //List<SelectListItem> loc = new List<SelectListItem>();
            //if (s == null)
            //{
            //    loc.Add(new SelectListItem { Text = "Hay chon kho", Value = "" });
            //}
            //else
            //{
            //    int id = Convert.ToInt32(s);
            //    loc.Add(new SelectListItem { Text = "All", Value = "*"});
            //    foreach (var l in le.SP_HOLDING_LIBLOCUSER_SEL(UserID, id).ToList())
            //    {
            //        loc.Add(new SelectListItem { Text = l.Symbol, Value = l.ID.ToString() });
            //    }
            //    ViewData["locId"] = loc.ToList();
            //}
            return View();
        }

        //GET LOCATIONS BY LIBRARY
        public JsonResult GetLocations(int id)
        {
            List<SelectListItem> loc = new List<SelectListItem>();
            loc.Add(new SelectListItem { Text = "Tất cả các kho", Value = "0" });
            foreach (var l in le.SP_HOLDING_LIBLOCUSER_SEL(UserID, id).ToList())
            {
                loc.Add(new SelectListItem { Text = l.Symbol, Value = l.ID.ToString() });
            }
            return Json(new SelectList(loc, "Value", "Text"));
        }

        [HttpPost]
        public ActionResult BaoCaoBoSung_New(int Library, int Location, int? ReNumber, DateTime? StartDate, DateTime? EndDate, int? SortBy, int? size, int? page, FormCollection collection)
        {

            String StartD = StartDate.ToString();
            String EndD = EndDate.ToString();
            int LibID = Library;
            int LocID = Location;
            String sdd = "", edd = "";
            string po = "";
            sdd = Request.Form["StartDate"].ToString();
            edd = Request.Form["EndDate"].ToString();
            String orderby = "";
            orderby = Request.Form["OrderBy"].ToString();
            po = Request.Form["PO"].ToString();
            if (String.IsNullOrEmpty(po))
            {
                List<Temper> tpt = new List<Temper>();
                if (orderby == "asc")
                {
                    if (sdd != "" && edd != "")
                    {
                        DateTime sdt = Convert.ToDateTime(sdd);
                        DateTime edt = Convert.ToDateTime(edd);
                        //List<Temper> tpt = new List<Temper>();
                        //đếm số nhập bằng cachs điếm sô lần xuất hiện của ISBN và kèm điều kiện ngày bổ xung hoặc locid
                        foreach (var item in le.FPT_SP_GET_HOLDING_BY_LOCATIONID_lan12(LibID, LocID, null, sdt, edt, orderby).ToList())
                        {
                            int temp = Int32.Parse(item.ItemID.ToString());
                            //check old or new book
                            string check = "";
                            foreach (var items in le.FPT_CHECK_ITEMID_AND_ACQUIREDATE(LocID, item.NgayBoSung.Value, temp).ToList())
                            {

                                check = items.ToString();
                            }
                            if (check != "")
                            {
                                //Temper tmpt = new Temper();
                                //string p = item.NgayChungTu.ToString();
                                // string p2 = item.NgayBoSung.ToString();
                                //string pp = item.DonGia.ToString();
                                //List<Temper> tpDKCB = new List<Temper>();
                                String tpDKCB = item.DKCB;
                                foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                                {
                                    // tpDKCB.Add(ites.DKCB, ites.ItemID);
                                    tpDKCB = ites.DKCB;
                                }
                                //string p = "", p2 = "";
                                //p = item.NgayChungTu.ToString();
                                //string thang = p.Substring(0, 2);
                                //string ngay = p.Substring(3, 2);
                                //string nam = p.Substring(6, 4);
                                //p2 = ngay + "/" + thang + "/" + nam;
                                tpt.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, "cũ", item.ItemID, 0, 0));
                            }
                            else
                            {
                                String tpDKCB = item.DKCB;
                                foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                                {
                                    // tpDKCB.Add(ites.DKCB, ites.ItemID);
                                    tpDKCB = ites.DKCB;
                                }
                                tpt.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, "Mới", item.ItemID, 0, 0));

                            }
                            //List<int> listIn = ;
                        }
                        ViewBag.AcqItems = tpt;
                        // ViewBag.tpt = tpt;
                    }
                    else if (edd != "" && sdd == "")
                    {
                        DateTime edt = Convert.ToDateTime(edd);
                        // ViewBag.AcqItems = le.FPT_SP_GET_HOLDING_BYLOC_TIME(LocID, null, null, edt, orderby).ToList();
                        //List<Temper> tpt = new List<Temper>();
                        foreach (var item in le.FPT_SP_GET_HOLDING_BY_LOCATIONID_lan12(LibID, LocID, null, null, edt, orderby).ToList())
                        {
                            int temp = Int32.Parse(item.ItemID.ToString());
                            string check = "";
                            foreach (var items in le.FPT_CHECK_ITEMID_AND_ACQUIREDATE(LocID, item.NgayBoSung.Value, temp).ToList())
                            {

                                check = items.ToString();
                            }
                            if (check != "")
                            {
                                //Temper tmpt = new Temper();
                                string p = item.NgayChungTu.ToString();
                                string p2 = item.NgayBoSung.ToString();
                                string pp = item.DonGia.ToString();
                                String tpDKCB = item.DKCB;
                                foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                                {
                                    // tpDKCB.Add(ites.DKCB, ites.ItemID);
                                    tpDKCB = ites.DKCB;
                                }
                                tpt.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, "cũ", item.ItemID, 0, 0));
                            }
                            else
                            {
                                String tpDKCB = item.DKCB;
                                foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                                {
                                    // tpDKCB.Add(ites.DKCB, ites.ItemID);
                                    tpDKCB = ites.DKCB;
                                }
                                tpt.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, "Mới", item.ItemID, 0, 0));

                            }
                            //List<int> listIn = ;
                        }
                        ViewBag.AcqItems = tpt;
                    }
                    else if (edd == "" && sdd != "")
                    {
                        DateTime sdt = Convert.ToDateTime(sdd);

                        foreach (var item in le.FPT_SP_GET_HOLDING_BY_LOCATIONID_lan12(LibID, LocID, null, sdt, null, orderby).ToList())
                        {
                            int temp = Int32.Parse(item.ItemID.ToString());
                            string check = "";
                            foreach (var items in le.FPT_CHECK_ITEMID_AND_ACQUIREDATE(LocID, item.NgayBoSung.Value, temp).ToList())
                            {

                                check = items.ToString();
                            }
                            if (check != "")
                            {
                                string p = item.NgayChungTu.ToString();
                                string p2 = item.NgayBoSung.ToString();
                                string pp = item.DonGia.ToString();
                                String tpDKCB = item.DKCB;
                                foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                                {
                                    tpDKCB = ites.DKCB;
                                }
                                tpt.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, "cũ", item.ItemID, 0, 0));
                            }
                            else
                            {
                                String tpDKCB = item.DKCB;
                                foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                                {
                                    tpDKCB = ites.DKCB;
                                }
                                tpt.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, "Mới", item.ItemID, 0, 0));

                            }
                        }
                        ViewBag.AcqItems = tpt;
                    }
                    else if (sdd == "" && edd == "")
                    {

                        foreach (var item in le.FPT_SP_GET_HOLDING_BY_LOCATIONID_lan12(LibID, LocID, null, null, null, orderby).ToList())
                        {
                            int temp = Int32.Parse(item.ItemID.ToString());
                            string check = "";
                            foreach (var items in le.FPT_CHECK_ITEMID_AND_ACQUIREDATE(LocID, item.NgayBoSung.Value, temp).ToList())
                            {

                                check = items.ToString();
                            }
                            if (check != "")
                            {
                                string p = item.NgayChungTu.ToString();
                                string p2 = item.NgayBoSung.ToString();
                                string pp = item.DonGia.ToString();
                                String tpDKCB = item.DKCB;
                                foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                                {
                                    tpDKCB = ites.DKCB;
                                }
                                tpt.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, "cũ", item.ItemID, 0, 0));
                            }
                            else
                            {
                                String tpDKCB = item.DKCB;
                                foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                                {
                                    tpDKCB = ites.DKCB;
                                }
                                tpt.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, "Mới", item.ItemID, 0, 0));

                            }
                            //List<int> listIn = ;
                        }

                        ViewBag.AcqItems = tpt;
                    }
                }//other
                else if (orderby == "desc")
                {
                    if (sdd != "" && edd != "")
                    {
                        DateTime sdt = Convert.ToDateTime(sdd);
                        DateTime edt = Convert.ToDateTime(edd);
                        //List<Temper> tpt = new List<Temper>();
                        foreach (var item in le.FPT_SP_GET_HOLDING_BY_LOCATIONID_lan12(LibID, LocID, null, sdt, edt, orderby).ToList())
                        {
                            int temp = Int32.Parse(item.ItemID.ToString());
                            string check = "";
                            foreach (var items in le.FPT_CHECK_ITEMID_AND_ACQUIREDATE(LocID, item.NgayBoSung.Value, temp).ToList())
                            {

                                check = items.ToString();
                            }
                            if (check != "")
                            {
                                //Temper tmpt = new Temper();
                                string p = item.NgayChungTu.ToString();
                                string p2 = item.NgayBoSung.ToString();
                                string pp = item.DonGia.ToString();
                                String tpDKCB = item.DKCB;
                                foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                                {
                                    // tpDKCB.Add(ites.DKCB, ites.ItemID);
                                    tpDKCB = ites.DKCB;
                                }
                                tpt.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, "cũ", item.ItemID, 0, 0));
                            }
                            else
                            {
                                String tpDKCB = item.DKCB;
                                foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                                {
                                    // tpDKCB.Add(ites.DKCB, ites.ItemID);
                                    tpDKCB = ites.DKCB;
                                }
                                tpt.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, "Mới", item.ItemID, 0, 0));

                            }
                            //List<int> listIn = ;
                        }
                        ViewBag.AcqItems = tpt;
                    }
                    else if (edd != "" && sdd == "")
                    {
                        DateTime edt = Convert.ToDateTime(edd);
                        //ViewBag.AcqItems = le.FPT_SP_GET_HOLDING_BYLOC_TIME(LocID, null, null, edt, orderby).ToList();
                        // List<Temper> tpt = new List<Temper>();
                        foreach (var item in le.FPT_SP_GET_HOLDING_BY_LOCATIONID_lan12(LibID, LocID, null, null, edt, orderby).ToList())
                        {
                            int temp = Int32.Parse(item.ItemID.ToString());
                            string check = "";
                            foreach (var items in le.FPT_CHECK_ITEMID_AND_ACQUIREDATE(LocID, item.NgayBoSung.Value, temp).ToList())
                            {

                                check = items.ToString();
                            }
                            if (check != "")
                            {
                                //Temper tmpt = new Temper();
                                string p = item.NgayChungTu.ToString();
                                string p2 = item.NgayBoSung.ToString();
                                string pp = item.DonGia.ToString();
                                String tpDKCB = item.DKCB;
                                foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                                {
                                    // tpDKCB.Add(ites.DKCB, ites.ItemID);
                                    tpDKCB = ites.DKCB;
                                }
                                tpt.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, "cũ", item.ItemID, 0, 0));
                            }
                            else
                            {
                                String tpDKCB = item.DKCB;
                                foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                                {
                                    // tpDKCB.Add(ites.DKCB, ites.ItemID);
                                    tpDKCB = ites.DKCB;
                                }
                                tpt.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, "Mới", item.ItemID, 0, 0));

                            }
                            //List<int> listIn = ;
                        }
                        ViewBag.AcqItems = tpt;
                    }
                    else if (edd == "" && sdd != "")
                    {
                        DateTime sdt = Convert.ToDateTime(sdd);
                        //ViewBag.AcqItems = le.FPT_SP_GET_HOLDING_BYLOC_TIME(LocID, null, sdt, null, orderby).ToList();
                        //List<Temper> tpt = new List<Temper>();
                        foreach (var item in le.FPT_SP_GET_HOLDING_BY_LOCATIONID_lan12(LibID, LocID, null, sdt, null, orderby).ToList())
                        {
                            int temp = Int32.Parse(item.ItemID.ToString());
                            string check = "";
                            foreach (var items in le.FPT_CHECK_ITEMID_AND_ACQUIREDATE(LocID, item.NgayBoSung.Value, temp).ToList())
                            {

                                check = items.ToString();
                            }
                            if (check != "")
                            {
                                //Temper tmpt = new Temper();
                                string p = item.NgayChungTu.ToString();
                                string p2 = item.NgayBoSung.ToString();
                                string pp = item.DonGia.ToString();

                                String tpDKCB = item.DKCB;
                                foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                                {
                                    // tpDKCB.Add(ites.DKCB, ites.ItemID);
                                    tpDKCB = ites.DKCB;
                                }
                                tpt.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, "cũ", item.ItemID, 0, 0));
                            }
                            else
                            {
                                String tpDKCB = item.DKCB;
                                foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                                {
                                    // tpDKCB.Add(ites.DKCB, ites.ItemID);
                                    tpDKCB = ites.DKCB;
                                }
                                tpt.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, "Mới", item.ItemID, 0, 0));

                            }
                            //List<int> listIn = ;
                        }
                        ViewBag.AcqItems = tpt;
                    }
                    else if (sdd == "" && edd == "")
                    {

                        //ViewBag.AcqItems = le.FPT_SP_GET_HOLDING_BYLOC_TIME(LocID, null, null, null, orderby).ToList();
                        //List<Temper> tpt = new List<Temper>();
                        foreach (var item in le.FPT_SP_GET_HOLDING_BY_LOCATIONID_lan12(LibID, LocID, null, null, null, orderby).ToList())
                        {
                            int temp = Int32.Parse(item.ItemID.ToString());
                            string check = "";
                            foreach (var items in le.FPT_CHECK_ITEMID_AND_ACQUIREDATE(LocID, item.NgayBoSung.Value, temp).ToList())
                            {

                                check = items.ToString();
                            }
                            if (check != "")
                            {
                                //Temper tmpt = new Temper();
                                string p = item.NgayChungTu.ToString();
                                string p2 = item.NgayBoSung.ToString();
                                string pp = item.DonGia.ToString();
                                String tpDKCB = item.DKCB;
                                foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                                {
                                    // tpDKCB.Add(ites.DKCB, ites.ItemID);
                                    tpDKCB = ites.DKCB;
                                }
                                tpt.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, "cũ", item.ItemID, 0, 0));
                            }
                            else
                            {
                                String tpDKCB = item.DKCB;
                                foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                                {
                                    // tpDKCB.Add(ites.DKCB, ites.ItemID);
                                    tpDKCB = ites.DKCB;
                                }
                                tpt.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, "Mới", item.ItemID, 0, 0));

                            }
                        }
                        ViewBag.AcqItems = tpt;
                    }
                }

                int slDauphay = 0;
                int slnhap = 0;
                int u = 1;
                int dem = 1;
                int indexGan = 0;
                int demso = 0;
                string ganString = "";


                ///tinh so luot sach nhap
                foreach (var item in ViewBag.AcqItems)
                {
                    //taoj mangr rooif check 2 phan tu lien tiep
                    //lấy số lương sách nhập
                    string nbs = "";
                    nbs = Convert.ToString(item.NgayBoSung);
                    if (nbs != "")
                    {
                        nbs = item.NgayBoSung;
                        nbs = nbs.Substring(0, nbs.IndexOf(" "));
                    }

                    int itid = item.ItemID;
                    Single dogia = Convert.ToSingle(item.DonGia);

                    foreach (var itm in le.FPT_BORROWNUMBER(itid, dogia, nbs))
                    {
                        int check = -1;
                        check = itm.Value;
                        if (check != -1)
                        {
                            slnhap = Convert.ToInt32(check);
                        }
                    }
                    item.SLN = slnhap;

                    decimal gia = (decimal)item.DonGia;
                    decimal a = item.SLN * gia;
                    item.ThanhTien = (double)a;



                }


                foreach (var item in ViewBag.AcqItems)
                {
                    string nbs = "";

                    nbs = Convert.ToString(item.NgayBoSung);
                    if (nbs != "")
                    {
                        nbs = item.NgayBoSung;
                        nbs = nbs.Substring(0, nbs.IndexOf(" "));
                    }

                    int itid = item.ItemID;
                    Single dogia = Convert.ToSingle(item.DonGia);


                    foreach (var itm in le.FPT_SP_GET_COPYNUMBER_STRING(LibID, nbs, dogia, itid))
                    {
                        string sts = "";
                        sts = itm.DKCB.ToString();
                        if (sts != "")
                        {
                            item.DKCB = itm.DKCB;
                        }
                    }
                }

                //gộp DKCB
                foreach (var item in ViewBag.AcqItems)
                {
                    string DKCBs = "";
                    DKCBs = item.DKCB;
                    char key = ',';
                    for (int i = 0; i < DKCBs.Length; i++)
                    {
                        if (DKCBs[i] == key)
                        {
                            slDauphay++;

                        }

                    }
                    slnhap = item.SLN;
                    String[] arrDK = new string[slDauphay + 1];
                    String[] arrDKfull = new string[slDauphay + 1];
                    string h = item.DKCB;
                    String ht = "";
                    String htt = "";
                    string lastStr = "";

                    if (slnhap > 1)
                    {
                        int indexDau = DKCBs.IndexOf(',');
                        if (indexDau > 0)
                        {
                            ht = DKCBs.Substring(0, indexDau);
                            lastStr = DKCBs.Substring(0, indexDau);
                        }
                        int bienphu = 0;
                        string[] arrDKCBs = new string[slDauphay + 1];
                        for (int i = 0; i < slDauphay; i++)
                        {
                            int checkDau = DKCBs.IndexOf(',');
                            if (checkDau > 0)
                            {
                                string strTempt = DKCBs.Substring(0, checkDau);
                                DKCBs = DKCBs.Substring(checkDau + 1);
                                strTempt = strTempt.Substring(strTempt.Length - 6, 6);
                                arrDKCBs[i] = strTempt;
                            }
                            bienphu++;

                        }
                        arrDKCBs[bienphu] = DKCBs.Substring(DKCBs.Length - 6, 6);

                        //PHAN CU
                        int kp = 0;
                        for (int m = 0; m < arrDKCBs.Length; m++)
                        {
                            bool cked = true;
                            int n = m + 1;
                            int intM = 0;
                            int intN = 0;
                            if (n < arrDKCBs.Length)
                            {
                                string strM = arrDKCBs[m];
                                intM = Int32.Parse(strM);
                                string strN = arrDKCBs[n];
                                intN = Int32.Parse(strN); ;
                                kp = intM + 1;
                            }

                            if (intN == kp)
                            {
                                if (n < arrDKCBs.Length)
                                {
                                    indexGan = n;
                                    ganString = arrDKCBs[n];
                                    ganString = ganString.Substring(4, 2);
                                    demso++;
                                }
                                else
                                {

                                }
                            }
                            else if (n == arrDKCBs.Length - 1)
                            {
                                //lastStr = lastStr.Substring(lastStr.Length - 6, 6);
                                if (lastStr == ht)
                                {
                                    ganString = arrDKCBs[m];
                                    ganString = ganString.Substring(4, 2);
                                    if (indexGan > 0)
                                    {
                                        int ck = arrDKCBs.Length;
                                        if (indexGan == ck)
                                        {
                                            htt = htt + "-" + ganString;

                                        }
                                        else if (indexGan < ck)
                                        {
                                            htt = htt + "-" + ganString + ",";

                                        }

                                    }
                                    else
                                    {
                                        int ck = arrDKCBs.Length;
                                        if (indexGan == ck)
                                        {
                                            htt = htt + "," + ganString;
                                        }
                                        else if (indexGan < ck)
                                        {
                                            htt = htt + ganString + ",";
                                        }
                                    }
                                }
                                else
                                {
                                    ganString = arrDKCBs[m];
                                    ganString = ganString.Substring(4, 2);
                                    int sDoi = Int32.Parse(ganString);
                                    int hieu = 0;
                                    hieu = sDoi - demso;
                                    if (hieu < 0)
                                    {
                                        hieu = hieu - (2 * hieu);
                                    }
                                    if (indexGan > 0)
                                    {
                                        int ck = arrDKCBs.Length;
                                        if (indexGan == ck)
                                        {

                                            htt = htt + hieu + "-" + ganString;
                                        }
                                        else if (indexGan < ck)
                                        {
                                            htt = htt + hieu + "-" + ganString + ",";
                                        }

                                    }
                                    else
                                    {
                                        int ck = arrDKCBs.Length;
                                        if (indexGan == ck)
                                        {
                                            htt = htt + "," + ganString;
                                        }
                                        else if (indexGan < ck)
                                        {
                                            htt = htt + ganString + ",";
                                        }
                                    }
                                }
                                ht = ganString;
                                indexGan = 0;
                                demso = 0;
                            }
                            else
                            {
                                if (lastStr == ht)
                                {
                                    ganString = arrDKCBs[m];
                                    ganString = ganString.Substring(4, 2);
                                    if (indexGan > 0)
                                    {
                                        int ck = arrDKCBs.Length;
                                        if (indexGan == ck)
                                        {
                                            htt = htt;

                                        }
                                        else if (indexGan < ck)
                                        {
                                            htt = htt + "-" + ganString + ",";

                                        }

                                    }
                                    else
                                    {
                                        int ck = arrDKCBs.Length;
                                        if (indexGan == ck)
                                        {
                                            htt = htt + ",";
                                        }
                                        else if (indexGan < ck)
                                        {
                                            htt = htt + ",";
                                        }
                                    }
                                }
                                else
                                {
                                    ganString = arrDKCBs[m];
                                    ganString = ganString.Substring(4, 2);
                                    int sDoi = Int32.Parse(ganString);
                                    int hieu = 0;
                                    hieu = sDoi - demso;
                                    if (hieu < 0)
                                    {
                                        hieu = hieu - (2 * hieu);
                                    }
                                    if (indexGan > 0)
                                    {
                                        int ck = arrDKCBs.Length;
                                        if (indexGan == ck)
                                        {

                                            htt = htt + hieu + "-" + ganString;
                                        }
                                        else if (indexGan < ck)
                                        {
                                            htt = htt + hieu + "-" + ganString + ",";
                                        }

                                    }
                                    else
                                    {
                                        int ck = arrDKCBs.Length;
                                        if (indexGan == ck)
                                        {
                                            htt = htt + "," + ganString;
                                        }
                                        else if (indexGan < ck)
                                        {
                                            htt = htt + ganString + ",";
                                        }
                                    }
                                }
                                ht = ganString;
                                indexGan = 0;
                                demso = 0;
                            }
                            //}
                        }
                        u = dem;

                        //CUOI
                        if (htt.LastIndexOf(',') > 0)
                        {
                            htt = htt.Substring(0, htt.LastIndexOf(','));
                        }

                        item.DKCB = lastStr + htt;

                    }
                    else if (slnhap == 1)
                    {
                        int hjk = 0;
                        hjk = DKCBs.IndexOf(',');
                        if (hjk == -1)
                        {
                            item.DKCB = DKCBs;
                        }
                        else
                        {
                            item.DKCB = DKCBs.Substring(0, hjk);
                        }
                        u++;

                    }

                    slDauphay = 0;
                }

            }
            else
            {
                List<Temper> listPO = new List<Temper>();
                int poiid = Convert.ToInt32(po);
                if (sdd == "" && edd == "")
                {
                    foreach (var item in le.FPT_SP_GET_HOLDING_BY_LOCATIONID_lan12(LibID, LocID, poiid, null, null, orderby).ToList())
                    {
                        String tpDKCB = item.DKCB;
                        foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                        {
                            // tpDKCB.Add(ites.DKCB, ites.ItemID);
                            tpDKCB = ites.DKCB;
                        }
                        int uCount = 0;
                        foreach (var itemss in le.FPT_SELECT_USECOUNT2(LibID, item.ItemID, item.NgayBoSung))
                        {
                            uCount += itemss.Value;
                        }
                        listPO.Add(new Temper(uCount, item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, "", item.ItemID, 0, 0));
                    }
                    ViewBag.POList = listPO;
                }
                else if (sdd != "" && edd == "")
                {
                    DateTime sdt = Convert.ToDateTime(sdd);
                    foreach (var item in le.FPT_SP_GET_HOLDING_BY_LOCATIONID_lan12(LibID, LocID, poiid, sdt, null, orderby).ToList())
                    {
                        String tpDKCB = item.DKCB;
                        foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                        {
                            // tpDKCB.Add(ites.DKCB, ites.ItemID);
                            tpDKCB = ites.DKCB;
                        }
                        int uCount = 0;
                        foreach (var itemss in le.FPT_SELECT_USECOUNT2(LibID, item.ItemID, item.NgayBoSung))
                        {
                            uCount += itemss.Value;
                        }
                        listPO.Add(new Temper(uCount, item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, "", item.ItemID, 0, 0));
                    }
                    ViewBag.POList = listPO;
                }
                else if (sdd == "" && edd != "")
                {
                    DateTime edt = Convert.ToDateTime(edd);
                    foreach (var item in le.FPT_SP_GET_HOLDING_BY_LOCATIONID_lan12(LibID, LocID, poiid, null, edt, orderby).ToList())
                    {
                        String tpDKCB = item.DKCB;
                        foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                        {
                            // tpDKCB.Add(ites.DKCB, ites.ItemID);
                            tpDKCB = ites.DKCB;
                        }
                        int uCount = 0;
                        foreach (var itemss in le.FPT_SELECT_USECOUNT2(LibID, item.ItemID, item.NgayBoSung))
                        {
                            uCount += itemss.Value;
                        }
                        listPO.Add(new Temper(uCount, item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, "", item.ItemID, 0, 0));
                    }
                    ViewBag.POList = listPO;
                }
                else if (sdd != "" && edd != "")
                {
                    DateTime sdt = Convert.ToDateTime(sdd);
                    DateTime edt = Convert.ToDateTime(edd);
                    foreach (var item in le.FPT_SP_GET_HOLDING_BY_LOCATIONID_lan12(LibID, LocID, poiid, sdt, edt, orderby).ToList())
                    {
                        String tpDKCB = item.DKCB;
                        foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                        {
                            // tpDKCB.Add(ites.DKCB, ites.ItemID);
                            tpDKCB = ites.DKCB;
                        }
                        int uCount = 0;
                        foreach (var itemss in le.FPT_SELECT_USECOUNT2(LibID, item.ItemID, item.NgayBoSung))
                        {
                            uCount += itemss.Value;
                        }
                        listPO.Add(new Temper(uCount, item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, "", item.ItemID, 0, 0));
                    }
                    ViewBag.POList = listPO;
                }


                int slDauphay = 0;
                int slnhap = 0;
                int u = 1;
                int dem = 1;
                int indexGan = 0;
                int demso = 0;
                string ganString = "";

                ///tinh so luot sach nhap
                foreach (var item in ViewBag.POList)
                {
                    //taoj mangr rooif check 2 phan tu lien tiep
                    //lấy số lương sách nhập
                    string nbs = "";
                    nbs = Convert.ToString(item.NgayBoSung);
                    if (nbs != "")
                    {
                        nbs = item.NgayBoSung;
                        nbs = nbs.Substring(0, nbs.IndexOf(" "));
                    }

                    int itid = item.ItemID;
                    Single dogia = Convert.ToSingle(item.DonGia);

                    foreach (var itm in le.FPT_BORROWNUMBER(itid, dogia, nbs))
                    {
                        int check = -1;
                        check = itm.Value;
                        if (check != -1)
                        {
                            slnhap = Convert.ToInt32(check);
                        }
                    }
                    item.SLN = slnhap;

                    decimal gia = (decimal)item.DonGia;
                    decimal a = item.SLN * gia;
                    item.ThanhTien = (double)a;



                }


                foreach (var item in ViewBag.POList)
                {
                    string nbs = "";

                    nbs = Convert.ToString(item.NgayBoSung);
                    if (nbs != "")
                    {
                        nbs = item.NgayBoSung;
                        nbs = nbs.Substring(0, nbs.IndexOf(" "));
                    }

                    int itid = item.ItemID;
                    Single dogia = Convert.ToSingle(item.DonGia);


                    foreach (var itm in le.FPT_SP_GET_COPYNUMBER_STRING(LibID, nbs, dogia, itid))
                    {
                        string sts = "";
                        sts = itm.DKCB.ToString();
                        if (sts != "")
                        {
                            item.DKCB = itm.DKCB;
                        }
                    }
                }

                //gộp DKCB
                foreach (var item in ViewBag.POList)
                {
                    string DKCBs = "";
                    DKCBs = item.DKCB;
                    char key = ',';
                    for (int i = 0; i < DKCBs.Length; i++)
                    {
                        if (DKCBs[i] == key)
                        {
                            slDauphay++;

                        }

                    }
                    slnhap = item.SLN;
                    String[] arrDK = new string[slDauphay + 1];
                    String[] arrDKfull = new string[slDauphay + 1];
                    string h = item.DKCB;
                    String ht = "";
                    String htt = "";
                    string lastStr = "";

                    if (slnhap > 1)
                    {
                        int indexDau = DKCBs.IndexOf(',');
                        if (indexDau > 0)
                        {
                            ht = DKCBs.Substring(0, indexDau);
                            lastStr = DKCBs.Substring(0, indexDau);
                        }
                        int bienphu = 0;
                        string[] arrDKCBs = new string[slDauphay + 1];
                        for (int i = 0; i < slDauphay; i++)
                        {
                            int checkDau = DKCBs.IndexOf(',');
                            if (checkDau > 0)
                            {
                                string strTempt = DKCBs.Substring(0, checkDau);
                                DKCBs = DKCBs.Substring(checkDau + 1);
                                strTempt = strTempt.Substring(strTempt.Length - 6, 6);
                                arrDKCBs[i] = strTempt;
                            }
                            bienphu++;

                        }
                        arrDKCBs[bienphu] = DKCBs.Substring(DKCBs.Length - 6, 6);

                        //PHAN CU
                        int kp = 0;
                        for (int m = 0; m < arrDKCBs.Length; m++)
                        {
                            bool cked = true;
                            int n = m + 1;
                            int intM = 0;
                            int intN = 0;
                            if (n < arrDKCBs.Length)
                            {
                                string strM = arrDKCBs[m];
                                intM = Int32.Parse(strM);
                                string strN = arrDKCBs[n];
                                intN = Int32.Parse(strN); ;
                                kp = intM + 1;
                            }

                            if (intN == kp)
                            {
                                if (n < arrDKCBs.Length)
                                {
                                    indexGan = n;
                                    ganString = arrDKCBs[n];
                                    ganString = ganString.Substring(4, 2);
                                    demso++;
                                }
                                else
                                {

                                }
                            }
                            else if (n == arrDKCBs.Length - 1)
                            {
                                //lastStr = lastStr.Substring(lastStr.Length - 6, 6);
                                if (lastStr == ht)
                                {
                                    ganString = arrDKCBs[m];
                                    ganString = ganString.Substring(4, 2);
                                    if (indexGan > 0)
                                    {
                                        int ck = arrDKCBs.Length;
                                        if (indexGan == ck)
                                        {
                                            htt = htt + "-" + ganString;

                                        }
                                        else if (indexGan < ck)
                                        {
                                            htt = htt + "-" + ganString + ",";

                                        }

                                    }
                                    else
                                    {
                                        int ck = arrDKCBs.Length;
                                        if (indexGan == ck)
                                        {
                                            htt = htt + "," + ganString;
                                        }
                                        else if (indexGan < ck)
                                        {
                                            htt = htt + ganString + ",";
                                        }
                                    }
                                }
                                else
                                {
                                    ganString = arrDKCBs[m];
                                    ganString = ganString.Substring(4, 2);
                                    int sDoi = Int32.Parse(ganString);
                                    int hieu = 0;
                                    hieu = sDoi - demso;
                                    if (hieu < 0)
                                    {
                                        hieu = hieu - (2 * hieu);
                                    }
                                    if (indexGan > 0)
                                    {
                                        int ck = arrDKCBs.Length;
                                        if (indexGan == ck)
                                        {

                                            htt = htt + hieu + "-" + ganString;
                                        }
                                        else if (indexGan < ck)
                                        {
                                            htt = htt + hieu + "-" + ganString + ",";
                                        }

                                    }
                                    else
                                    {
                                        int ck = arrDKCBs.Length;
                                        if (indexGan == ck)
                                        {
                                            htt = htt + "," + ganString;
                                        }
                                        else if (indexGan < ck)
                                        {
                                            htt = htt + ganString + ",";
                                        }
                                    }
                                }
                                ht = ganString;
                                indexGan = 0;
                                demso = 0;
                            }
                            else
                            {
                                if (lastStr == ht)
                                {
                                    ganString = arrDKCBs[m];
                                    ganString = ganString.Substring(4, 2);
                                    if (indexGan > 0)
                                    {
                                        int ck = arrDKCBs.Length;
                                        if (indexGan == ck)
                                        {
                                            htt = htt;

                                        }
                                        else if (indexGan < ck)
                                        {
                                            htt = htt + "-" + ganString + ",";

                                        }

                                    }
                                    else
                                    {
                                        int ck = arrDKCBs.Length;
                                        if (indexGan == ck)
                                        {
                                            htt = htt + ",";
                                        }
                                        else if (indexGan < ck)
                                        {
                                            htt = htt + ",";
                                        }
                                    }
                                }
                                else
                                {
                                    ganString = arrDKCBs[m];
                                    ganString = ganString.Substring(4, 2);
                                    int sDoi = Int32.Parse(ganString);
                                    int hieu = 0;
                                    hieu = sDoi - demso;
                                    if (hieu < 0)
                                    {
                                        hieu = hieu - (2 * hieu);
                                    }
                                    if (indexGan > 0)
                                    {
                                        int ck = arrDKCBs.Length;
                                        if (indexGan == ck)
                                        {

                                            htt = htt + hieu + "-" + ganString;
                                        }
                                        else if (indexGan < ck)
                                        {
                                            htt = htt + hieu + "-" + ganString + ",";
                                        }

                                    }
                                    else
                                    {
                                        int ck = arrDKCBs.Length;
                                        if (indexGan == ck)
                                        {
                                            htt = htt + "," + ganString;
                                        }
                                        else if (indexGan < ck)
                                        {
                                            htt = htt + ganString + ",";
                                        }
                                    }
                                }
                                ht = ganString;
                                indexGan = 0;
                                demso = 0;
                            }
                            //}
                        }
                        u = dem;

                        //CUOI
                        if (htt.LastIndexOf(',') > 0)
                        {
                            htt = htt.Substring(0, htt.LastIndexOf(','));
                        }

                        item.DKCB = lastStr + htt;

                    }
                    else if (slnhap == 1)
                    {
                        int hjk = 0;
                        hjk = DKCBs.IndexOf(',');
                        if (hjk == -1)
                        {
                            item.DKCB = DKCBs;
                        }
                        else
                        {
                            item.DKCB = DKCBs.Substring(0, hjk);
                        }
                        u++;

                    }

                    slDauphay = 0;
                }

            }

            List<Temper> display1 = new List<Temper>();
            List<Temper> display2 = new List<Temper>();
            List<Temper> display3 = new List<Temper>();
            List<Temper> display4 = new List<Temper>();
            List<Temper> display5 = new List<Temper>();
            List<Temper> display6 = new List<Temper>();
            Temper temp1 = null;
            Temper temp2 = null;
            Temper temp3 = null;
            Temper temp4 = null;
            Temper temp5 = null;
            Temper temp6 = null;

            if (ViewBag.AcqItems != null)
            {

                foreach (var item in ViewBag.AcqItems)
                {
                    string st = "";
                    try
                    {
                        st = item.DonViTienTe;
                        if (st != null)
                        {
                            st = st.Replace(" ", "");
                        }

                        if (st == "VND")
                        {
                            string ngayct = "";
                            string ngaybosug = "";
                            ngayct = item.NgayChungTu.ToString();
                            ngayct = ngayct.Substring(0, ngayct.IndexOf(" "));
                            ngaybosug = item.NgayBoSung.ToString();
                            ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                            if (ngayct != "")
                            {
                                temp1 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, ngayct, item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);

                            }
                            else
                            {
                                temp1 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);

                            }

                            display1.Add(temp1);
                        }
                        if (st == "YEN")
                        {
                            string ngayct = "";
                            string ngaybosug = "";
                            ngayct = item.NgayChungTu.ToString();
                            ngaybosug = item.NgayBoSung.ToString();
                            if (ngayct != null)
                            {
                                ngayct = ngayct.Substring(0, ngayct.IndexOf(" "));
                                ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                                temp2 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, ngayct, item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                            }
                            else
                            {
                                temp2 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);

                            }
                            display2.Add(temp2);
                            // display2.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung.ToString(), item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien));
                        }
                        if (st == "USD")
                        {
                            string ngayct = "";
                            string ngaybosug = "";
                            ngayct = item.NgayChungTu.ToString();
                            ngaybosug = item.NgayBoSung.ToString();
                            if (ngayct != null)
                            {
                                ngayct = ngayct.Substring(0, ngayct.IndexOf(" "));
                                ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                                temp3 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, ngayct, item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                            }
                            else
                            {
                                temp3 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);

                            }
                            display3.Add(temp3);
                            // display3.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung.ToString(), item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien));
                        }
                        if (st == "B?NGANH")
                        {
                            string ngayct = "";
                            string ngaybosug = "";
                            ngayct = item.NgayChungTu.ToString();
                            ngaybosug = item.NgayBoSung.ToString();
                            if (ngayct != null)
                            {
                                ngayct = ngayct.Substring(0, ngayct.IndexOf(" "));
                                ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                                temp4 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, ngayct, item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                            }
                            else
                            {
                                temp4 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);

                            }
                            display4.Add(temp4);
                            //  display4.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung.ToString(), item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien));
                        }
                        if (st == "CENT")
                        {
                            string ngayct = "";
                            string ngaybosug = "";
                            ngayct = item.NgayChungTu.ToString();
                            ngaybosug = item.NgayBoSung.ToString();
                            if (ngayct != null)
                            {
                                ngayct = ngayct.Substring(0, ngayct.IndexOf(" "));
                                ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                                temp5 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, ngayct, item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                            }
                            else
                            {
                                temp5 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);

                            }
                            display5.Add(temp5);
                            // display5.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung.ToString(), item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien));
                        }
                        if (st == "EUR")
                        {
                            string ngayct = "";
                            string ngaybosug = "";
                            ngayct = item.NgayChungTu.ToString();
                            ngaybosug = item.NgayBoSung.ToString();
                            if (ngayct != null)
                            {
                                ngayct = ngayct.Substring(0, ngayct.IndexOf(" "));
                                ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                                temp6 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, ngayct, item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                            }
                            else
                            {
                                temp6 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);

                            }
                            display6.Add(temp6);
                            //display6.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung.ToString(), item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien));
                        }

                    }
                    catch (Exception e)
                    {
                        e.ToString();
                    }

                }

            }
            else if (ViewBag.POList != null)
            {
                foreach (var item in ViewBag.POList)
                {
                    string st = "";

                    st = item.DonViTienTe;
                    if (st != null)
                    {
                        st = st.Replace(" ", "");
                    }

                    if (st == "VND")
                    {
                        string ngayct = "";
                        string ngaybosug = "";
                        ngayct = item.NgayChungTu.ToString();
                        ngaybosug = item.NgayBoSung.ToString();
                        if (ngayct != null)
                        {
                            int ngaycct = ngayct.IndexOf(" ");
                            if (ngaycct > 0)
                            {
                                ngayct = ngayct.Substring(0, ngaycct);
                            }
                            ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                            temp1 = new Temper(item.UseCount, item.POID, item.SoChungTu, item.NhanDe, item.ISBN, ngayct,
                                item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        else
                        {
                            temp1 = new Temper(item.UseCount, item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu,
                                item.DKCB, item.NgayBoSung, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                        }

                        display1.Add(temp1);
                    }
                    if (st == "YEN")
                    {
                        string ngayct = "";
                        string ngaybosug = "";
                        ngayct = item.NgayChungTu.ToString();
                        ngaybosug = item.NgayBoSung.ToString();
                        if (ngayct != null)
                        {
                            int ngaycct = ngayct.IndexOf(" ");
                            if (ngaycct > 0)
                            {
                                ngayct = ngayct.Substring(0, ngaycct);
                            }
                            ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                            temp2 = new Temper(item.UseCount, item.POID, item.SoChungTu, item.NhanDe, item.ISBN, ngayct,
                                item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        else
                        {
                            temp2 = new Temper(item.UseCount, item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu,
                                item.DKCB, item.NgayBoSung, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        display2.Add(temp2);
                        // display2.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung.ToString(), item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien));
                    }
                    if (st == "USD")
                    {
                        string ngayct = "";
                        string ngaybosug = "";
                        ngayct = item.NgayChungTu.ToString();
                        ngaybosug = item.NgayBoSung.ToString();
                        if (ngayct != null)
                        {
                            int ngaycct = ngayct.IndexOf(" ");
                            if (ngaycct > 0)
                            {
                                ngayct = ngayct.Substring(0, ngaycct);
                            }

                            ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                            temp3 = new Temper(item.UseCount, item.POID, item.SoChungTu, item.NhanDe, item.ISBN, ngayct,
                                item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        else
                        {
                            temp3 = new Temper(item.UseCount, item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu,
                                item.DKCB, item.NgayBoSung, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        display3.Add(temp3);
                        // display3.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung.ToString(), item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien));
                    }
                    if (st == "B?NGANH")
                    {
                        string ngayct = "";
                        string ngaybosug = "";
                        ngayct = item.NgayChungTu.ToString();
                        ngaybosug = item.NgayBoSung.ToString();
                        if (ngayct != null)
                        {
                            int ngaycct = ngayct.IndexOf(" ");
                            if (ngaycct > 0)
                            {
                                ngayct = ngayct.Substring(0, ngaycct);
                            }
                            ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                            temp4 = new Temper(item.UseCount, item.POID, item.SoChungTu, item.NhanDe, item.ISBN, ngayct,
                                item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        else
                        {
                            temp4 = new Temper(item.UseCount, item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu,
                                item.DKCB, item.NgayBoSung, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        display4.Add(temp4);
                        //  display4.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung.ToString(), item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien));
                    }
                    if (st == "CENT")
                    {
                        string ngayct = "";
                        string ngaybosug = "";
                        ngayct = item.NgayChungTu.ToString();
                        ngaybosug = item.NgayBoSung.ToString();
                        if (ngayct != null)
                        {
                            int ngaycct = ngayct.IndexOf(" ");
                            if (ngaycct > 0)
                            {
                                ngayct = ngayct.Substring(0, ngaycct);
                            }
                            ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                            temp5 = new Temper(item.UseCount, item.POID, item.SoChungTu, item.NhanDe, item.ISBN, ngayct,
                                item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        else
                        {
                            temp5 = new Temper(item.UseCount, item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu,
                                item.DKCB, item.NgayBoSung, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        display5.Add(temp5);
                        // display5.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung.ToString(), item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien));
                    }
                    if (st == "EUR")
                    {
                        string ngayct = "";
                        string ngaybosug = "";
                        ngayct = item.NgayChungTu.ToString();
                        ngaybosug = item.NgayBoSung.ToString();
                        if (ngayct != null)
                        {
                            int ngaycct = ngayct.IndexOf(" ");
                            if (ngaycct > 0)
                            {
                                ngayct = ngayct.Substring(0, ngaycct);
                            }
                            ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                            temp6 = new Temper(item.UseCount, item.POID, item.SoChungTu, item.NhanDe, item.ISBN, ngayct,
                                item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        else
                        {
                            temp6 = new Temper(item.UseCount, item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu,
                                item.DKCB, item.NgayBoSung, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        display6.Add(temp6);
                        //display6.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung.ToString(), item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien));
                    }
                }
            }
            //check null VND
            if (display1.Count == 0)
            {
                ViewBag.DisVND = null;
            }
            else
            {
                ViewBag.DisVND = display1.ToList();

            }
            List<Temper> test = null;
            //check null
            if (display2.Count == 0)
            {
                ViewBag.DisYEN = null;
            }
            else
            {
                ViewBag.DisYEN = display2;
            }
            //check null
            if (display3.Count == 0)
            {
                ViewBag.DisUSD = null;
            }
            else
            {
                ViewBag.DisUSD = display3.ToList();
            }
            //check null
            if (display4.Count == 0)
            {
                ViewBag.DisBAnh = null;
            }
            else
            {
                ViewBag.DisBAnh = display4.ToList();
            }

            //check null
            if (display5.Count == 0)
            {
                ViewBag.DisCENT = null;
            }
            else
            {
                ViewBag.DisCENT = display5.ToList();
            }
            //check null
            if (display6.Count == 0)
            {
                ViewBag.DisEUR = null;
            }
            else
            {
                ViewBag.DisEUR = display6.ToList();
            }


            return View();
        }

        public ActionResult AcquireStatisticIndex()
        {
            return View();
        }
        public ActionResult LanguageStat()
        {
            return View();
        }
        public ActionResult StatisticYear()
        {
            List<SelectListItem> lib = new List<SelectListItem>
            {
                new SelectListItem { Text = "Hãy chọn thư viện", Value = "" }
            };
            foreach (var l in le.SP_HOLDING_LIB_SEL(UserID).ToList())
            {
                lib.Add(new SelectListItem { Text = l.Code, Value = l.ID.ToString() });
            }
            ViewData["lib"] = lib;            
            return View();
        }
        [HttpPost]
        public PartialViewResult GetYearStats(string strLibID, string strLocID, string strFromYear, string strToYear)
        {
            int LibID = 0;
            int LocID = 0;
            if (!String.IsNullOrEmpty(strLibID)) LibID = Convert.ToInt32(strLibID);
            if (!String.IsNullOrEmpty(strLocID)) LocID = Convert.ToInt32(strLocID);
            ViewBag.Result = ab.FPT_ACQ_YEAR_STATISTIC_LIST(LibID, LocID, strFromYear, strToYear, UserID);
            return PartialView("GetYearStats");
        }
        public ActionResult StatisticMonth()
        {
            List<SelectListItem> lib = new List<SelectListItem>
            {
                new SelectListItem { Text = "Hãy chọn thư viện", Value = "" }
            };
            foreach (var l in le.SP_HOLDING_LIB_SEL(UserID).ToList())
            {
                lib.Add(new SelectListItem { Text = l.Code, Value = l.ID.ToString() });
            }
            ViewData["lib"] = lib;
            return View();
        }
        [HttpPost]
        public PartialViewResult GetMonthStats(string strLibID, string strLocID, string strInYear)
        {
            int LibID = 0;
            int LocID = 0;
            if (!String.IsNullOrEmpty(strLibID)) LibID = Convert.ToInt32(strLibID);
            if (!String.IsNullOrEmpty(strLocID)) LocID = Convert.ToInt32(strLocID);
            ViewBag.Result = ab.FPT_ACQ_MONTH_STATISTIC_LIST(LibID, LocID, strInYear, UserID);
            return PartialView("GetMonthStats");
        }
        public ActionResult LiquidationStats()
        {
            List<SelectListItem> lib = new List<SelectListItem>
            {
                new SelectListItem { Text = "Hãy chọn thư viện", Value = "" }
            };
            foreach (var l in le.SP_HOLDING_LIB_SEL(UserID).ToList())
            {
                lib.Add(new SelectListItem { Text = l.Code, Value = l.ID.ToString() });
            }
            ViewData["lib"] = lib;
            return View();
        }
        public PartialViewResult GetLiquidationStats(string strLiquidID, string strLibID, string strLocID, string strFromDate, string strToDate)
        {
            int LibID = 0;
            int LocID = 0;
            if (!String.IsNullOrEmpty(strLibID)) LibID = Convert.ToInt32(strLibID);
            if (!String.IsNullOrEmpty(strLocID)) LocID = Convert.ToInt32(strLocID);
            ViewBag.Result = ab.FPT_GET_LIQUIDBOOKS_LIST(strLiquidID, LibID, LocID, strFromDate, strToDate, UserID);
            foreach(var item in ViewBag.Result)
            {
                item.Content = GetContent(item.Content);
            }
            ViewBag.LiquidCode = strLiquidID;
            return PartialView("GetLiquidationStats");
        }
        public ActionResult RecomendReport()
        {
            List<SelectListItem> lib = new List<SelectListItem>();
            lib.Add(new SelectListItem { Text = "Hãy chọn thư viện", Value = "" });
            foreach (var l in le.SP_HOLDING_LIB_SEL(UserID).ToList())
            {
                lib.Add(new SelectListItem { Text = l.Code, Value = l.ID.ToString() });
            }
            ViewData["lib"] = lib;
            return View();
        }
        public ActionResult GetRecomendReport(int Library, int Location, int? ReNumber, DateTime? StartDate, DateTime? EndDate, int? SortBy, int? size, int? page, FormCollection collection)
        {
            String StartD = StartDate.ToString();
            String EndD = EndDate.ToString();
            int LibID = Library;
            int LocID = Location;
            String sdd = "", edd = "";
            string recomCode = "";
            sdd = Request.Form["StartDate"].ToString();
            edd = Request.Form["EndDate"].ToString();
            String orderby = "";
            orderby = Request.Form["OrderBy"].ToString();
            recomCode = Request.Form["recomCode"].ToString();
            if (String.IsNullOrEmpty(recomCode))
            {
                recomCode = null;
            }

            List<Temper> listPO = new List<Temper>();
            if (sdd == "" && edd == "")
            {
                foreach (var item in le.FPT_SP_GET_HOLDING_BY_RECOMMENDID(LibID, LocID, recomCode, null, null, orderby).ToList())
                {
                    String tpDKCB = item.DKCB;
                    foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                    {
                        // tpDKCB.Add(ites.DKCB, ites.ItemID);
                        tpDKCB = ites.DKCB;
                    }
                    int uCount = 0;
                    foreach (var itemss in le.FPT_SELECT_USECOUNT2(LibID, item.ItemID, item.NgayBoSung))
                    {
                        uCount += itemss.Value;
                    }
                    string isb = "";
                    foreach (var ite in le.FPT_JOIN_ISBN(item.ItemID))
                    {
                        isb = ite.ISBN;
                    }
                    listPO.Add(new Temper(uCount, item.RECOMMENDID, item.SoChungTu, item.NhanDe, isb, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, item.ItemID, 0, 0));
                }
                ViewBag.POList = listPO;
            }
            else if (sdd != "" && edd == "")
            {
                DateTime sdt = Convert.ToDateTime(sdd);
                foreach (var item in le.FPT_SP_GET_HOLDING_BY_RECOMMENDID(LibID, LocID, recomCode, sdt, null, orderby).ToList())
                {
                    String tpDKCB = item.DKCB;
                    foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                    {
                        // tpDKCB.Add(ites.DKCB, ites.ItemID);
                        tpDKCB = ites.DKCB;
                    }
                    int uCount = 0;
                    foreach (var itemss in le.FPT_SELECT_USECOUNT2(LibID, item.ItemID, item.NgayBoSung))
                    {
                        uCount += itemss.Value;
                    }
                    string isb = "";
                    foreach (var ite in le.FPT_JOIN_ISBN(item.ItemID))
                    {
                        isb = ite.ISBN;
                    }
                    listPO.Add(new Temper(uCount, item.RECOMMENDID, item.SoChungTu, item.NhanDe, isb, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, item.ItemID, 0, 0));
                }
                ViewBag.POList = listPO;
            }
            else if (sdd == "" && edd != "")
            {
                DateTime edt = Convert.ToDateTime(edd);
                foreach (var item in le.FPT_SP_GET_HOLDING_BY_RECOMMENDID(LibID, LocID, recomCode, null, edt, orderby).ToList())
                {
                    String tpDKCB = item.DKCB;
                    foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                    {
                        // tpDKCB.Add(ites.DKCB, ites.ItemID);
                        tpDKCB = ites.DKCB;
                    }
                    int uCount = 0;
                    foreach (var itemss in le.FPT_SELECT_USECOUNT2(LibID, item.ItemID, item.NgayBoSung))
                    {
                        uCount += itemss.Value;
                    }
                    string isb = "";
                    foreach (var ite in le.FPT_JOIN_ISBN(item.ItemID))
                    {
                        isb = ite.ISBN;
                    }
                    listPO.Add(new Temper(uCount, item.RECOMMENDID, item.SoChungTu, item.NhanDe, isb, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, item.ItemID, 0, 0));
                }
                ViewBag.POList = listPO;
            }
            else if (sdd != "" && edd != "")
            {
                DateTime sdt = Convert.ToDateTime(sdd);
                DateTime edt = Convert.ToDateTime(edd);
                foreach (var item in le.FPT_SP_GET_HOLDING_BY_RECOMMENDID(LibID, LocID, recomCode, sdt, edt, orderby).ToList())
                {
                    String tpDKCB = item.DKCB;
                    foreach (var ites in le.FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE(item.ItemID, item.NgayBoSung.Value).ToList())
                    {
                        // tpDKCB.Add(ites.DKCB, ites.ItemID);
                        tpDKCB = ites.DKCB;
                    }
                    int uCount = 0;
                    foreach (var itemss in le.FPT_SELECT_USECOUNT2(LibID, item.ItemID, item.NgayBoSung))
                    {
                        uCount += itemss.Value;
                    }
                    string isb = "";
                    foreach (var ite in le.FPT_JOIN_ISBN(item.ItemID))
                    {
                        isb = ite.ISBN;
                    }
                    listPO.Add(new Temper(uCount, item.RECOMMENDID, item.SoChungTu, item.NhanDe, isb, item.NgayChungTu.ToString(), tpDKCB, item.NgayBoSung.ToString(), item.IdNhaXuatBan, item.NamXuatBan, item.DonGia.Value, item.DonViTienTe, item.ItemID, 0, 0));
                }
                ViewBag.POList = listPO;
            }


            int slDauphay = 0;
            int slnhap = 0;
            int u = 1;
            int dem = 1;
            int indexGan = 0;
            int demso = 0;
            string ganString = "";

            ///tinh so luot sach nhap
            foreach (var item in ViewBag.POList)
            {
                //taoj mangr rooif check 2 phan tu lien tiep
                //lấy số lương sách nhập
                string nbs = "";
                nbs = Convert.ToString(item.NgayBoSung);
                if (nbs != "")
                {
                    nbs = item.NgayBoSung;
                    nbs = nbs.Substring(0, nbs.IndexOf(" "));
                }

                int itid = item.ItemID;
                Single dogia = Convert.ToSingle(item.DonGia);

                foreach (var itm in le.FPT_BORROWNUMBER(itid, dogia, nbs))
                {
                    int check = -1;
                    check = itm.Value;
                    if (check != -1)
                    {
                        slnhap = Convert.ToInt32(check);
                    }
                }
                item.SLN = slnhap;

                decimal gia = (decimal)item.DonGia;
                decimal a = item.SLN * gia;
                item.ThanhTien = (double)a;



            }


            foreach (var item in ViewBag.POList)
            {
                string nbs = "";

                nbs = Convert.ToString(item.NgayBoSung);
                if (nbs != "")
                {
                    nbs = item.NgayBoSung;
                    nbs = nbs.Substring(0, nbs.IndexOf(" "));
                }

                int itid = item.ItemID;
                Single dogia = Convert.ToSingle(item.DonGia);


                foreach (var itm in le.FPT_SP_GET_COPYNUMBER_STRING(LibID, nbs, dogia, itid))
                {
                    string sts = "";
                    sts = itm.DKCB.ToString();
                    if (sts != "")
                    {
                        item.DKCB = itm.DKCB;
                    }
                }
            }

            //gộp DKCB
            foreach (var item in ViewBag.POList)
            {
                string DKCBs = "";
                DKCBs = item.DKCB;
                char key = ',';
                for (int i = 0; i < DKCBs.Length; i++)
                {
                    if (DKCBs[i] == key)
                    {
                        slDauphay++;

                    }

                }
                slnhap = item.SLN;
                String[] arrDK = new string[slDauphay + 1];
                String[] arrDKfull = new string[slDauphay + 1];
                string h = item.DKCB;
                String ht = "";
                String htt = "";
                string lastStr = "";

                if (slnhap > 1)
                {
                    int indexDau = DKCBs.IndexOf(',');
                    if (indexDau > 0)
                    {
                        ht = DKCBs.Substring(0, indexDau);
                        lastStr = DKCBs.Substring(0, indexDau);
                    }
                    int bienphu = 0;
                    string[] arrDKCBs = new string[slDauphay + 1];
                    for (int i = 0; i < slDauphay; i++)
                    {
                        int checkDau = DKCBs.IndexOf(',');
                        if (checkDau > 0)
                        {
                            string strTempt = DKCBs.Substring(0, checkDau);
                            DKCBs = DKCBs.Substring(checkDau + 1);
                            strTempt = strTempt.Substring(strTempt.Length - 6, 6);
                            arrDKCBs[i] = strTempt;
                        }
                        bienphu++;

                    }
                    arrDKCBs[bienphu] = DKCBs.Substring(DKCBs.Length - 6, 6);

                    //PHAN CU
                    int kp = 0;
                    for (int m = 0; m < arrDKCBs.Length; m++)
                    {
                        bool cked = true;
                        int n = m + 1;
                        int intM = 0;
                        int intN = 0;
                        if (n < arrDKCBs.Length)
                        {
                            string strM = arrDKCBs[m];
                            intM = Int32.Parse(strM);
                            string strN = arrDKCBs[n];
                            intN = Int32.Parse(strN); ;
                            kp = intM + 1;
                        }

                        if (intN == kp)
                        {
                            if (n < arrDKCBs.Length)
                            {
                                indexGan = n;
                                ganString = arrDKCBs[n];
                                ganString = ganString.Substring(4, 2);
                                demso++;
                            }
                            else
                            {

                            }
                        }
                        else if (n == arrDKCBs.Length - 1)
                        {
                            //lastStr = lastStr.Substring(lastStr.Length - 6, 6);
                            if (lastStr == ht)
                            {
                                ganString = arrDKCBs[m];
                                ganString = ganString.Substring(4, 2);
                                if (indexGan > 0)
                                {
                                    int ck = arrDKCBs.Length;
                                    if (indexGan == ck)
                                    {
                                        htt = htt + "-" + ganString;

                                    }
                                    else if (indexGan < ck)
                                    {
                                        htt = htt + "-" + ganString + ",";

                                    }

                                }
                                else
                                {
                                    int ck = arrDKCBs.Length;
                                    if (indexGan == ck)
                                    {
                                        htt = htt + "," + ganString;
                                    }
                                    else if (indexGan < ck)
                                    {
                                        htt = htt + ganString + ",";
                                    }
                                }
                            }
                            else
                            {
                                ganString = arrDKCBs[m];
                                ganString = ganString.Substring(4, 2);
                                int sDoi = Int32.Parse(ganString);
                                int hieu = 0;
                                hieu = sDoi - demso;
                                if (hieu < 0)
                                {
                                    hieu = hieu - (2 * hieu);
                                }
                                if (indexGan > 0)
                                {
                                    int ck = arrDKCBs.Length;
                                    if (indexGan == ck)
                                    {

                                        htt = htt + hieu + "-" + ganString;
                                    }
                                    else if (indexGan < ck)
                                    {
                                        htt = htt + hieu + "-" + ganString + ",";
                                    }

                                }
                                else
                                {
                                    int ck = arrDKCBs.Length;
                                    if (indexGan == ck)
                                    {
                                        htt = htt + "," + ganString;
                                    }
                                    else if (indexGan < ck)
                                    {
                                        htt = htt + ganString + ",";
                                    }
                                }
                            }
                            ht = ganString;
                            indexGan = 0;
                            demso = 0;
                        }
                        else
                        {
                            if (lastStr == ht)
                            {
                                ganString = arrDKCBs[m];
                                ganString = ganString.Substring(4, 2);
                                if (indexGan > 0)
                                {
                                    int ck = arrDKCBs.Length;
                                    if (indexGan == ck)
                                    {
                                        htt = htt;

                                    }
                                    else if (indexGan < ck)
                                    {
                                        htt = htt + "-" + ganString + ",";

                                    }

                                }
                                else
                                {
                                    int ck = arrDKCBs.Length;
                                    if (indexGan == ck)
                                    {
                                        htt = htt + ",";
                                    }
                                    else if (indexGan < ck)
                                    {
                                        htt = htt + ",";
                                    }
                                }
                            }
                            else
                            {
                                ganString = arrDKCBs[m];
                                ganString = ganString.Substring(4, 2);
                                int sDoi = Int32.Parse(ganString);
                                int hieu = 0;
                                hieu = sDoi - demso;
                                if (hieu < 0)
                                {
                                    hieu = hieu - (2 * hieu);
                                }
                                if (indexGan > 0)
                                {
                                    int ck = arrDKCBs.Length;
                                    if (indexGan == ck)
                                    {

                                        htt = htt + hieu + "-" + ganString;
                                    }
                                    else if (indexGan < ck)
                                    {
                                        htt = htt + hieu + "-" + ganString + ",";
                                    }

                                }
                                else
                                {
                                    int ck = arrDKCBs.Length;
                                    if (indexGan == ck)
                                    {
                                        htt = htt + "," + ganString;
                                    }
                                    else if (indexGan < ck)
                                    {
                                        htt = htt + ganString + ",";
                                    }
                                }
                            }
                            ht = ganString;
                            indexGan = 0;
                            demso = 0;
                        }
                        //}
                    }
                    u = dem;

                    //CUOI
                    if (htt.LastIndexOf(',') > 0)
                    {
                        htt = htt.Substring(0, htt.LastIndexOf(','));
                    }

                    item.DKCB = lastStr + htt;

                }
                else if (slnhap == 1)
                {
                    int hjk = 0;
                    hjk = DKCBs.IndexOf(',');
                    if (hjk == -1)
                    {
                        item.DKCB = DKCBs;
                    }
                    else
                    {
                        item.DKCB = DKCBs.Substring(0, hjk);
                    }
                    u++;

                }

                slDauphay = 0;
            }

            // }

            List<Temper> display1 = new List<Temper>();
            List<Temper> display2 = new List<Temper>();
            List<Temper> display3 = new List<Temper>();
            List<Temper> display4 = new List<Temper>();
            List<Temper> display5 = new List<Temper>();
            List<Temper> display6 = new List<Temper>();
            Temper temp1 = null;
            Temper temp2 = null;
            Temper temp3 = null;
            Temper temp4 = null;
            Temper temp5 = null;
            Temper temp6 = null;

            if (ViewBag.AcqItems != null)
            {

                foreach (var item in ViewBag.AcqItems)
                {
                    string st = "";
                    try
                    {
                        st = item.DonViTienTe;
                        if (st != null)
                        {
                            st = st.Replace(" ", "");
                        }

                        if (st == "VND")
                        {
                            string ngayct = "";
                            string ngaybosug = "";
                            ngayct = item.NgayChungTu.ToString();
                            ngayct = ngayct.Substring(0, ngayct.IndexOf(" "));
                            ngaybosug = item.NgayBoSung.ToString();
                            ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                            if (ngayct != "")
                            {
                                temp1 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, ngayct, item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);

                            }
                            else
                            {
                                temp1 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);

                            }

                            display1.Add(temp1);
                        }
                        if (st == "YEN")
                        {
                            string ngayct = "";
                            string ngaybosug = "";
                            ngayct = item.NgayChungTu.ToString();
                            ngaybosug = item.NgayBoSung.ToString();
                            if (ngayct != null)
                            {
                                ngayct = ngayct.Substring(0, ngayct.IndexOf(" "));
                                ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                                temp2 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, ngayct, item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                            }
                            else
                            {
                                temp2 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);

                            }
                            display2.Add(temp2);
                            // display2.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung.ToString(), item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien));
                        }
                        if (st == "USD")
                        {
                            string ngayct = "";
                            string ngaybosug = "";
                            ngayct = item.NgayChungTu.ToString();
                            ngaybosug = item.NgayBoSung.ToString();
                            if (ngayct != null)
                            {
                                ngayct = ngayct.Substring(0, ngayct.IndexOf(" "));
                                ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                                temp3 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, ngayct, item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                            }
                            else
                            {
                                temp3 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);

                            }
                            display3.Add(temp3);
                            // display3.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung.ToString(), item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien));
                        }
                        if (st == "B?NGANH")
                        {
                            string ngayct = "";
                            string ngaybosug = "";
                            ngayct = item.NgayChungTu.ToString();
                            ngaybosug = item.NgayBoSung.ToString();
                            if (ngayct != null)
                            {
                                ngayct = ngayct.Substring(0, ngayct.IndexOf(" "));
                                ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                                temp4 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, ngayct, item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                            }
                            else
                            {
                                temp4 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);

                            }
                            display4.Add(temp4);
                            //  display4.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung.ToString(), item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien));
                        }
                        if (st == "CENT")
                        {
                            string ngayct = "";
                            string ngaybosug = "";
                            ngayct = item.NgayChungTu.ToString();
                            ngaybosug = item.NgayBoSung.ToString();
                            if (ngayct != null)
                            {
                                ngayct = ngayct.Substring(0, ngayct.IndexOf(" "));
                                ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                                temp5 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, ngayct, item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                            }
                            else
                            {
                                temp5 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);

                            }
                            display5.Add(temp5);
                            // display5.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung.ToString(), item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien));
                        }
                        if (st == "EUR")
                        {
                            string ngayct = "";
                            string ngaybosug = "";
                            ngayct = item.NgayChungTu.ToString();
                            ngaybosug = item.NgayBoSung.ToString();
                            if (ngayct != null)
                            {
                                ngayct = ngayct.Substring(0, ngayct.IndexOf(" "));
                                ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                                temp6 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, ngayct, item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);
                            }
                            else
                            {
                                temp6 = new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien);

                            }
                            display6.Add(temp6);
                            //display6.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung.ToString(), item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien));
                        }

                    }
                    catch (Exception e)
                    {
                        e.ToString();
                    }

                }

            }
            else if (ViewBag.POList != null)
            {
                foreach (var item in ViewBag.POList)
                {
                    listTempt.Add(new Temper(item.UseCount, item.ReId, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu,
                                item.DKCB, item.NgayBoSung, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.ItemID, item.SLN, item.ThanhTien));
                    string st = "";

                    st = item.DonViTienTe;
                    if (st != null)
                    {
                        st = st.Replace(" ", "");
                    }

                    if (st == "VND")
                    {
                        string ngayct = "";
                        string ngaybosug = "";
                        ngayct = item.NgayChungTu.ToString();
                        ngaybosug = item.NgayBoSung.ToString();
                        if (ngayct != null)
                        {
                            int ngaycct = ngayct.IndexOf(" ");
                            if (ngaycct > 0)
                            {
                                ngayct = ngayct.Substring(0, ngaycct);
                            }
                            ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                            temp1 = new Temper(item.UseCount, item.ReId, item.SoChungTu, item.NhanDe, item.ISBN, ngayct,
                                item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        else
                        {
                            temp1 = new Temper(item.UseCount, item.ReId, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu,
                                item.DKCB, item.NgayBoSung, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.ItemID, item.SLN, item.ThanhTien);
                        }

                        display1.Add(temp1);
                    }
                    if (st == "YEN")
                    {
                        string ngayct = "";
                        string ngaybosug = "";
                        ngayct = item.NgayChungTu.ToString();
                        ngaybosug = item.NgayBoSung.ToString();
                        if (ngayct != null)
                        {
                            int ngaycct = ngayct.IndexOf(" ");
                            if (ngaycct > 0)
                            {
                                ngayct = ngayct.Substring(0, ngaycct);
                            }
                            ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                            temp2 = new Temper(item.UseCount, item.ReId, item.SoChungTu, item.NhanDe, item.ISBN, ngayct,
                                item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        else
                        {
                            temp2 = new Temper(item.UseCount, item.ReId, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu,
                                item.DKCB, item.NgayBoSung, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        display2.Add(temp2);
                        // display2.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung.ToString(), item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien));
                    }
                    if (st == "USD")
                    {
                        string ngayct = "";
                        string ngaybosug = "";
                        ngayct = item.NgayChungTu.ToString();
                        ngaybosug = item.NgayBoSung.ToString();
                        if (ngayct != null)
                        {
                            int ngaycct = ngayct.IndexOf(" ");
                            if (ngaycct > 0)
                            {
                                ngayct = ngayct.Substring(0, ngaycct);
                            }

                            ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                            temp3 = new Temper(item.UseCount, item.ReId, item.SoChungTu, item.NhanDe, item.ISBN, ngayct,
                                item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        else
                        {
                            temp3 = new Temper(item.UseCount, item.ReId, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu,
                                item.DKCB, item.NgayBoSung, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        display3.Add(temp3);
                        // display3.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung.ToString(), item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien));
                    }
                    if (st == "B?NGANH")
                    {
                        string ngayct = "";
                        string ngaybosug = "";
                        ngayct = item.NgayChungTu.ToString();
                        ngaybosug = item.NgayBoSung.ToString();
                        if (ngayct != null)
                        {
                            int ngaycct = ngayct.IndexOf(" ");
                            if (ngaycct > 0)
                            {
                                ngayct = ngayct.Substring(0, ngaycct);
                            }
                            ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                            temp4 = new Temper(item.UseCount, item.ReId, item.SoChungTu, item.NhanDe, item.ISBN, ngayct,
                                item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        else
                        {
                            temp4 = new Temper(item.UseCount, item.ReId, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu,
                                item.DKCB, item.NgayBoSung, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        display4.Add(temp4);
                        //  display4.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung.ToString(), item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien));
                    }
                    if (st == "CENT")
                    {
                        string ngayct = "";
                        string ngaybosug = "";
                        ngayct = item.NgayChungTu.ToString();
                        ngaybosug = item.NgayBoSung.ToString();
                        if (ngayct != null)
                        {
                            int ngaycct = ngayct.IndexOf(" ");
                            if (ngaycct > 0)
                            {
                                ngayct = ngayct.Substring(0, ngaycct);
                            }
                            ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                            temp5 = new Temper(item.UseCount, item.ReId, item.SoChungTu, item.NhanDe, item.ISBN, ngayct,
                                item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        else
                        {
                            temp5 = new Temper(item.UseCount, item.ReId, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu,
                                item.DKCB, item.NgayBoSung, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        display5.Add(temp5);
                        // display5.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung.ToString(), item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien));
                    }
                    if (st == "EUR")
                    {
                        string ngayct = "";
                        string ngaybosug = "";
                        ngayct = item.NgayChungTu.ToString();
                        ngaybosug = item.NgayBoSung.ToString();
                        if (ngayct != null)
                        {
                            int ngaycct = ngayct.IndexOf(" ");
                            if (ngaycct > 0)
                            {
                                ngayct = ngayct.Substring(0, ngaycct);
                            }
                            ngaybosug = ngaybosug.Substring(0, ngaybosug.IndexOf(" "));
                            temp6 = new Temper(item.UseCount, item.ReId, item.SoChungTu, item.NhanDe, item.ISBN, ngayct,
                                item.DKCB, ngaybosug, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        else
                        {
                            temp6 = new Temper(item.UseCount, item.ReId, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu,
                                item.DKCB, item.NgayBoSung, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
                                item.DonViTienTe, item.ItemID, item.SLN, item.ThanhTien);
                        }
                        display6.Add(temp6);
                        //display6.Add(new Temper(item.POID, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu.ToString(), item.DKCB, item.NgayBoSung.ToString(), item.NhaXuatBan, item.NamXuatBan, item.DonGia, item.DonViTienTe, item.TinhTrangSach, item.ItemID, item.SLN, item.ThanhTien));
                    }
                }
            }
            //check null VND
            if (display1.Count == 0)
            {
                ViewBag.DisVND = null;
            }
            else
            {
                ViewBag.DisVND = display1.ToList();

            }
            List<Temper> test = null;
            //check null
            if (display2.Count == 0)
            {
                ViewBag.DisYEN = null;
            }
            else
            {
                ViewBag.DisYEN = display2;
            }
            //check null
            if (display3.Count == 0)
            {
                ViewBag.DisUSD = null;
            }
            else
            {
                ViewBag.DisUSD = display3.ToList();
            }
            //check null
            if (display4.Count == 0)
            {
                ViewBag.DisBAnh = null;
            }
            else
            {
                ViewBag.DisBAnh = display4.ToList();
            }

            //check null
            if (display5.Count == 0)
            {
                ViewBag.DisCENT = null;
            }
            else
            {
                ViewBag.DisCENT = display5.ToList();
            }
            //check null
            if (display6.Count == 0)
            {
                ViewBag.DisEUR = null;
            }
            else
            {
                ViewBag.DisEUR = display6.ToList();
            }


            return View();
        }
        //    protected void export_Click(object sender, EventArgs e)
        //    {
        //        DataTable dtSource = new DataTable("Temper");
        //        if (ViewBag.DisVND != null)
        //        {
        //            foreach (var item in ViewBag.DisVND)
        //            {
        //                dtSource.Rows.Add(new Temper(item.UseCount, item.ReId, item.SoChungTu, item.NhanDe, item.ISBN, item.NgayChungTu,
        //                            item.DKCB, item.NgayBoSung, item.NhaXuatBan, item.NamXuatBan, item.DonGia,
        //                            item.DonViTienTe, item.ItemID, item.SLN, item.ThanhTien));
        //            }
        //        }

        //        GenerateWord(dtSource);
        //    }

        //    public static void GenerateWord(DataTable dtSource)
        //    {
        //        StringBuilder sbDocBody = new StringBuilder(); ;
        //        try
        //        {
        //            // Declare Styles
        //            sbDocBody.Append("<style>");
        //            sbDocBody.Append(".Header {  background-color:Navy; color:#ffffff; font-weight:bold;font-family:Verdana; font-size:12px;}");
        //            sbDocBody.Append(".SectionHeader { background-color:#8080aa; color:#ffffff; font-family:Verdana; font-size:12px;font-weight:bold;}");
        //            sbDocBody.Append(".Content { background-color:#ccccff; color:#000000; font-family:Verdana; font-size:12px;text-align:left}");
        //            sbDocBody.Append(".Label { background-color:#ccccee; color:#000000; font-family:Verdana; font-size:12px; text-align:right;}");
        //            sbDocBody.Append("</style>");
        //            //
        //            StringBuilder sbContent = new StringBuilder(); ;
        //            sbDocBody.Append("<br><table align=\"center\" cellpadding=1 cellspacing=0 style=\"background-color:#000000;\">");
        //            sbDocBody.Append("<tr><td width=\"500\">");
        //            sbDocBody.Append("<table width=\"100%\" cellpadding=1 cellspacing=2 style=\"background-color:#ffffff;\">");
        //            //
        //            if (dtSource.Rows.Count > 0)
        //            {
        //                sbDocBody.Append("<tr><td>");
        //                sbDocBody.Append("<table width=\"600\" cellpadding=\"0\" cellspacing=\"2\"><tr><td>");
        //                //
        //                // Add Column Headers
        //                sbDocBody.Append("<tr><td width=\"25\"> </td></tr>");
        //                sbDocBody.Append("<tr>");
        //                sbDocBody.Append("<td> </td>");
        //                for (int i = 0; i < dtSource.Columns.Count; i++)
        //                {
        //                    sbDocBody.Append("<td class=\"Header\" width=\"120\">" + dtSource.Columns[i].ToString().Replace(".", "<br>") + "</td>");
        //                }
        //                sbDocBody.Append("</tr>");
        //                //
        //                // Add Data Rows
        //                for (int i = 0; i < dtSource.Rows.Count; i++)
        //                {
        //                    sbDocBody.Append("<tr>");
        //                    sbDocBody.Append("<td> </td>");
        //                    for (int j = 0; j < dtSource.Columns.Count; j++)
        //                    {
        //                        sbDocBody.Append("<td class=\"Content\">" + dtSource.Rows[i][j].ToString() + "</td>");
        //                    }
        //                    sbDocBody.Append("</tr>");
        //                }
        //                sbDocBody.Append("</table>");
        //                sbDocBody.Append("</td></tr></table>");
        //                sbDocBody.Append("</td></tr></table>");
        //            }
        //            //
        //            //HttpContext.Current.Response.Clear();
        //            //HttpContext.Current.Response.Buffer = true;
        //            ////
        //            //HttpContext.Current.Response.AppendHeader("Content-Type", "application/msword");
        //            //HttpContext.Current.Response.AppendHeader("Content-disposition", "attachment; filename=EmployeeDetails.doc");
        //            //HttpContext.Current.Response.Write(sbDocBody.ToString());
        //            //HttpContext.Current.Response.End();
        //        }
        //        catch (Exception ex)
        //        {
        //            // Ignore this error as this is caused due to termination of the Response Stream.
        //        }
        //    }
    }

}