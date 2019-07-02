USE [Libol]
GO
/****** Object:  StoredProcedure [dbo].[FPT_EDU_GET_SHELF_CONTENT]    ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[FPT_EDU_GET_SHELF_CONTENT]
@itemCode as varchar(100)
AS
BEGIN
	DECLARE @ID as int
	SET  @ID= (SELECT (ID) FROM [ITEM] WHERE Code = @itemCode)
	SELECT FieldCode,  Content FROM Field000s WHERE ItemID = @ID
		UNION ALL SELECT FieldCode,  Content FROM Field100s WHERE ItemID = @ID
		UNION ALL SELECT FieldCode, Content FROM Field200s WHERE ItemID = @ID
		UNION ALL SELECT FieldCode, Content FROM Field300s WHERE ItemID = @ID
		UNION ALL SELECT FieldCode, Content FROM Field400s WHERE ItemID = @ID
		UNION ALL SELECT FieldCode, Content FROM Field500s WHERE ItemID = @ID
		UNION ALL SELECT FieldCode, Content FROM Field600s WHERE ItemID = @ID
		UNION ALL SELECT FieldCode, Content FROM Field700s WHERE ItemID = @ID
		UNION ALL SELECT FieldCode, Content FROM Field800s WHERE ItemID = @ID
		UNION ALL SELECT FieldCode, Content FROM Field900s WHERE ItemID = @ID
END
