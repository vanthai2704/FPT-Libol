﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.Models;
using Libol.EntityResult;
using System.Data.Entity.Core.Objects;

namespace Libol.Controllers
{
    public class CatalogueController : Controller
    {
        private LibolEntities db = new LibolEntities();
        CatalogueBusiness catalogueBusiness = new CatalogueBusiness();
        // GET: Catalogue
        public ActionResult MainTab()
        {

            return View();
        }



        //----------------Add New Cata ----------------
        //---------------------------------------------
        public ActionResult AddNewCatalogue()
        {
            //get list marc form
            ViewData["ListMarcForm"] = db.FPT_SP_CATA_GET_MARC_FORM(0, 0).ToList();
            //Cấp thư mục
            ViewData["listLevelDir"] = db.CAT_DIC_DIRLEVEL.OrderBy(d => d.Description).ToList();
            ViewData["ListRecordType"] = db.CAT_DIC_RECORDTYPE.OrderBy(r => r.Description).ToList();
            ViewData["listItemType"] = db.CAT_DIC_ITEM_TYPE.Where(t => !String.IsNullOrEmpty(t.TypeName)).OrderBy(t => t.TypeName).ToList();
            //vật mang tin
            ViewData["listMedium"] = db.CAT_DIC_MEDIUM.Where(m => !String.IsNullOrEmpty(m.Description)).OrderBy(m => m.Description).ToList();

            byte[] listAccessLevel = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
            ViewData["listAccessLevel"] = listAccessLevel;

            return View();
        }

        //Check Tittle
        [HttpPost]
        public JsonResult CheckTitle(string strTitle, string strItemType)
        {
            //catalogueBusiness.CheckExistNumber("9781184", "020$a");
            //string fieldCode = GetFieldByID(intIsAuthority,"", intFormID);
            //strTitle = "N'" + strTitle +"'";
            // comment tại đây:
            //List<FPT_SP_CATA_CHECK_EXIST_TITLE_2019_Result> titleList = db.FPT_SP_CATA_CHECK_EXIST_TITLE_2019(strTitle, strItemType).ToList();
            //return Json(titleList, JsonRequestBehavior.AllowGet);
            return Json("", JsonRequestBehavior.AllowGet);
        }

        //Check ISBN
        [HttpPost]
        public JsonResult CheckItemNumber(string strFieldValue, string strFieldCode)
        {
            //ObjectParameter Output = new ObjectParameter("lngItemID", typeof(Int32));
            //db.FPT_SP_CATA_CHECK_EXIST_ITEMNUMBER(strFieldValue, strFieldCode, Output);
            //return Json(Output.Value, JsonRequestBehavior.AllowGet);
            return Json("", JsonRequestBehavior.AllowGet);
        }



        [HttpPost]
        public JsonResult LoadFormComplated(int intIsAuthority, int intFormID)
        {
            //catalogueBusiness.CheckExistNumber("9781184", "020$a");
            //string fieldCode = GetFieldByID(intIsAuthority,"", intFormID);
            List<GET_CATALOGUE_FIELDS_Result> formComplated = catalogueBusiness.GetComplatedForm(0, "", intFormID);
            ViewData["MarcFormComplated"] = formComplated;

            return Json(formComplated, JsonRequestBehavior.AllowGet);
        }

        //----------------Add Item For Detail -----------
        //---------------------------------------------


        [HttpPost]
        public JsonResult InsertOrUpdateCatalogue(List<string> listFieldsName, List<string> listFieldsValue)
        {
            string code = catalogueBusiness.HandleListFields(listFieldsName, listFieldsValue);
            string itemID = db.ITEMs.Where( i=> i.Code == code).Select( i=> i.ID).FirstOrDefault().ToString();
            string[] data = { code,itemID };
            return Json(data, JsonRequestBehavior.AllowGet);

        }

        [HttpPost]
        public JsonResult GetComplatedFormForDetail(int intIsAuthority, int intFormID)
        {
            //catalogueBusiness.CheckExistNumber("9781184", "020$a");
            //string fieldCode = GetFieldByID(intIsAuthority,"", intFormID);
            List<GET_CATALOGUE_FIELDS_Result> formComplated = catalogueBusiness.GetComplatedFormForDetail(0, "", intFormID);
            ViewData["MarcFormComplated"] = formComplated;

            return Json(formComplated, JsonRequestBehavior.AllowGet);
        }


        //----------------Search Field Cata -----------
        //---------------------------------------------
        public ActionResult SearchCodeNumber()
        {
            return View();
        }

        [HttpPost]
        public JsonResult SearchCode(string strCode, string strCN, string strTT)
        {
            List<FPT_SP_CATA_GET_DETAILINFOR_OF_ITEM_Result> inforList = catalogueBusiness.SearchCode(strCode, strCN, strTT);
            return Json(inforList, JsonRequestBehavior.AllowGet);
        }




        //----------------Detail Cata -----------
        //---------------------------------------------
        public ActionResult AddNewCatalogueDetail()
        {
            string Id = Request["ID"];
            string strFieldCode = "";
            if (Id != "")
            {
                List<SP_CATA_GET_CONTENTS_OF_ITEMS_Result> listContent = catalogueBusiness.GetContentByID(Id).ToList();
                //Lay Content cua LEADER
                ViewData["Leader"] = listContent[0];
                listContent.RemoveAt(0);
                //Ghep Cac truong trung nhau thanh 1 dong
                List<int> index = new List<int>();
                for (int i = 0; i < listContent.Count; i++)
                {
                    if(i > 0)
                    {
                        if (listContent[i].FieldCode == listContent[i - 1].FieldCode)
                        {
                            index.Add(i-1);
                            listContent[i].Content = listContent[i-1].Content + "::" + listContent[i].Content;
                        }
                    }
                    
                }
                //remove các trường trùng đã được ghép
                for (int i = 0; i < index.Count; i++)
                {
                    listContent.RemoveAt(index[i] - i);
                }

                ViewData["ListContent"] = listContent;
                
                //get mô tả từng trường
                foreach (SP_CATA_GET_CONTENTS_OF_ITEMS_Result item in listContent)
                {
                    strFieldCode = strFieldCode + item.IDSort + ",";
                }

                List<SP_CATA_GET_MODIFIED_FIELDS_Result> listField = catalogueBusiness.FPT_SP_CATA_GET_MODIFIED_FIELDS(0, 0, strFieldCode, "", "", 0).ToList();

                ViewData["ListField"] = listField;
            }

            return View();
        }
    }

   

}