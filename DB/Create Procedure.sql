create PROCEDURE [dbo].[FPT_SP_CATA_GET_MARC_FORM]
-- ---------   ------  -------------------------------------------
	@intFormID	int,
	@intIsAuthority	int
AS
	DECLARE @strSelectStatement	nvarchar(150)

	IF @intIsAuthority = 0
		BEGIN
			SELECT * FROM MARC_WORKSHEET
			IF NOT @intFormID = 0
				SELECT * FROM MARC_WORKSHEET WHERE ID = + CAST(@intFormID AS CHAR(4))
		END
	ELSE
		BEGIN
			SELECT * FROM MARC_AUTHORITY_WORKSHEET
			IF NOT @intFormID = 0
				SELECT * FROM MARC_AUTHORITY_WORKSHEET WHERE ID =  CAST(@intFormID AS CHAR(4))
		END
		Go
create  PROCEDURE [dbo].[FPT_SP_CATA_GETFIELDS_OF_FORM]
-- ---------   ------  -------------------------------------------
	@intFormID	int,
	@strCreator	nvarchar(50),
	@intIsAuthority	int
AS
	DECLARE @strSelectStatement	nvarchar(300)
	IF @intIsAuthority = 0
		BEGIN		
			IF NOT @intFormID = 0	
				SELECT * FROM MARC_WORKSHEET A LEFT JOIN MARC_BIB_WS_DETAIL B ON A.ID = B.FormID WHERE A.ID =  + CAST(@intFormID AS CHAR(4))
		END
	ELSE 
	-- Authority data
		BEGIN
			SET @strSelectStatement = ''
			IF NOT @intFormID = 0	
				SELECT * FROM MARC_AUTHORITY_WORKSHEET A LEFT JOIN MARC_AUTHORITY_WS_DETAIL B ON A.ID = B.FormID WHERE A.ID = + CAST(@intFormID AS CHAR(4))
		END
	
	Go
	create PROCEDURE [dbo].[FPT_SP_CATA_CHECK_EXIST_TITLE]
-- ---------   ------  -------------------------------------------
	@strTitle	nvarchar(200),
	@strItemType	varchar(5)
   -- Declare program variables as shown above
AS
	DECLARE @strSelectStatement	nvarchar(500)
	IF NOT @strItemType = ''
	-- Forming SelectStatement
		SELECT ItemID, Content FROM FIELD200S WHERE FieldCode = '245' AND Content LIKE N'$a' + @strTitle + '%' AND ItemID IN (SELECT TOP 50 A.TypeID FROM ITEM A, CAT_DIC_ITEM_TYPE B WHERE A.TypeID = B.ID AND UPPER(B.TypeCode) = UPPER('' + RTRIM(@strItemType) + ''))
	ELSE
		SELECT ItemID, Content FROM FIELD200S WHERE FieldCode = '245' AND Content LIKE N'$a' + @strTitle + '%'
	-- Execute