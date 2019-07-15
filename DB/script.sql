go
CREATE FUNCTION [dbo].[ufn_removeMark] (@text nvarchar(max))
RETURNS nvarchar(max)
AS
BEGIN
	SET @text = LOWER(@text)
	DECLARE @textLen int = LEN(@text)
	IF @textLen > 0
	BEGIN
		DECLARE @index int = 1
		DECLARE @lPos int
		DECLARE @SIGN_CHARS nvarchar(100) = N'ăâđêôơưàảãạáằẳẵặắầẩẫậấèẻẽẹéềểễệếìỉĩịíòỏõọóồổỗộốờởỡợớùủũụúừửữựứỳỷỹỵýđð'
		DECLARE @UNSIGN_CHARS varchar(100) = 'aadeoouaaaaaaaaaaaaaaaeeeeeeeeeeiiiiiooooooooooooooouuuuuuuuuuyyyyydd'

		WHILE @index <= @textLen
		BEGIN
			SET @lPos = CHARINDEX(SUBSTRING(@text,@index,1),@SIGN_CHARS)
			IF @lPos > 0
			BEGIN
				SET @text = STUFF(@text,@index,1,SUBSTRING(@UNSIGN_CHARS,@lPos,1))
			END
			SET @index = @index + 1
		END
	END
	RETURN @text
END

go
/******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO
CREATE TABLE SYS_USER_GOOGLE_ACCOUNT(
	Email varchar(500) NOT NULL PRIMARY KEY,
	ID INT NOT NULL
)

/****** Object:  Table [dbo].[FPT_RECOMMEND]    Script Date: 07/07/2019 19:01:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[FPT_RECOMMEND](
	[POID] [int] NOT NULL,
	[ReID] [varchar](30) NOT NULL,
 CONSTRAINT [PK_FPT_RECOMMEND] PRIMARY KEY CLUSTERED 
(
	[POID] ASC,
	[ReID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[FPT_RECOMMEND]  WITH CHECK ADD  CONSTRAINT [FK_FPT_RECOMMEND_ACQ_PO] FOREIGN KEY([POID])
REFERENCES [dbo].[ACQ_PO] ([ID])
GO

ALTER TABLE [dbo].[FPT_RECOMMEND] CHECK CONSTRAINT [FK_FPT_RECOMMEND_ACQ_PO]
GO

/******/
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

/******/
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

/******/
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

	go
/******/
	CREATE PROC [dbo].[FPT_SP_ILL_SEARCH_PATRON] 
-- Purpose: Search Patron update search khong dau
@strPatronName NVARCHAR(50),  
@strPatronCode VARCHAR(50)  
AS  
DECLARE @strSQL NVARCHAR(500)  
	SET @strSQL='select*,dbo.ufn_removeMark(FullName) as FullNameSimple from(select Code,ValidDate,ExpiredDate,DOB,(IsNull(FirstName,'''') + '' '' + IsNull(MiddleName +'' '' ,'''')  + IsNull(LastName,'''')) AS FullName from CIR_PATRON '
	
	IF @strPatronCode <>'' 
		SET @strSQL=@strSQL + ' AND Code LIKE ''' + @strPatronCode + ''''  
	
	SET @strSQL=@strSQL + ') A'
	IF @strPatronName<>'' 
		SET @strSQL=@strSQL + ' WHERE A.FullName  LIKE N''%' + @strPatronName + '%'' or dbo.ufn_removeMark(FullName) like dbo.ufn_removeMark(N''%' + @strPatronName + '%'')'

EXECUTE(@strSQL)

go
/******/
CREATE      PROCEDURE [dbo].[FPT_SP_CIR_GET_RENEW]
	@intUserID	INT,
	@intType	SMALLINT,
	@strCodeVal	VARCHAR(50)
AS
	DECLARE	@strSQLSel  NVARCHAR(2000)
	DECLARE	@strSQLTab  NVARCHAR(100)
	DECLARE	@strSQLJoin  NVARCHAR(1000)

	SET @strSQLSel='SELECT Content, Renewals, RenewalPeriod, TimeUnit, FirstName + '' '' + MiddleName + '' '' + LastName AS FullName
	, CIR_PATRON.Code, CIR_LOAN.*, '' '' AS strNote, '' '' AS TimeHold ,getdate() as Today' 
	SET @strSQLTab='CIR_PATRON, CIR_LOAN_TYPE, CIR_LOAN, HOLDING,FIELD200S'
	SET @strSQLJoin=' CIR_PATRON.ID=CIR_LOAN.PatronID AND CIR_LOAN.LoanTypeID=CIR_LOAN_TYPE.ID AND HOLDING.CopyNumber=CIR_LOAN.CopyNumber AND CIR_LOAN.DueDate IS NOT NULL
	AND HOLDING.ItemID=CIR_LOAN.ItemID AND HOLDING.LocationID IN(SELECT LocationID FROM SYS_USER_CIR_LOCATION WHERE UserID = ' + RTrim(CAST(@intUserID AS CHAR)) + ') 
	AND FIELD200S.ItemID=CIR_LOAN.ItemID AND FIELD200S.FieldCode=''245'''
	IF @intType=1
		SET @strSQLJoin=@strSQLJoin + ' AND CIR_PATRON.Code=''' + @strCodeVal + ''''
	IF @intType=2
		BEGIN
			SET @strSQLTab=@strSQLTab + ',ITEM'
			SET @strSQLJoin=@strSQLJoin + ' AND ITEM.ID=CIR_LOAN.ItemID AND ITEM.Code=''' + @strCodeVal + ''''
		END
	IF @intType=3
		SET @strSQLJoin=@strSQLJoin + ' AND CIR_LOAN.CopyNumber=''' + @strCodeVal + ''''

	EXEC(@strSQLSel + ' FROM ' + @strSQLTab + ' WHERE ' +  @strSQLJoin)

go
/******/
CREATE PROCEDURE [dbo].[FPT_ADMIN_GET_RIGHTS_ACCEPT]
	@intModuleID int,
	@intUserID int
AS
SELECT R.ID, R.[Right] FROM SYS_USER_RIGHT_DETAIL D JOIN SYS_USER_RIGHT R ON D.RightID = R.ID
WHERE D.UserID = @intUserID AND R.ModuleID = @intModuleID

go
/******/
CREATE PROCEDURE [dbo].[FPT_ADMIN_GET_RIGHTS_DENY]
	@intModuleID int,
	@intUserID int,
	@intUserParentID int
AS

SELECT R.ID, R.[Right] FROM SYS_USER_RIGHT R 
JOIN SYS_USER_RIGHT_DETAIL D ON R.ID = D.RightID 
WHERE R.ModuleID = @intModuleID AND D.UserID = @intUserParentID AND R.ID 
NOT IN (
	SELECT U.ID FROM SYS_USER_RIGHT_DETAIL D JOIN SYS_USER_RIGHT U ON D.RightID = U.ID
	WHERE D.UserID = @intUserID AND U.ModuleID = @intModuleID
)

go
/******/
CREATE PROCEDURE [dbo].[FPT_ADMIN_GET_RIGHTS_WHEN_CREATE]
	@intModuleID int,
	@intParentID int,
	@IsBasic int
AS

SELECT R.ID, R.[Right] FROM SYS_USER_RIGHT R 
JOIN SYS_USER_RIGHT_DETAIL D ON R.ID = D.RightID 
JOIN SYS_USER E ON D.UserID = E.ID 
WHERE D.UserID = @intParentID AND R.ModuleID = @intModuleID AND R.IsBasic = @IsBasic


go
/******/
Create PROCEDURE [dbo].[FPT_ACQ_MONTH_STATISTIC] 
	@intLibraryID int,
	@intLocationID int,
	@strInYear varchar(4),
	@intUserID int
AS
	DECLARE @strSQL varchar(1000)
	DECLARE @strJoinSQL varchar(1000)
	DECLARE @strLikeSql varchar(1000)
		
	SET @strSQL = 'SELECT MONTH(AcquiredDate) AS Month, Count(DISTINCT ItemID) AS BooksTotal, COUNT(*) AS CopiesTotal, 
    MoneyTotal = SUM(ISNULL(Price,0)) '
	SET @strJoinSQL = 'FROM HOLDING '
	SET @strLikeSql = '1 =1 AND '
	
	IF NOT @intLibraryID = 0
		BEGIN		
			IF NOT @intLocationID = 0
				SET @strLikeSQL = @strLikeSQL + 'LocationID = ' + CAST(@intLocationID AS VARCHAR(10)) +' AND '
			ELSE
				SET @strLikeSQL = @strLikeSQL + 'LibID = ' + CAST(@intLibraryID AS VARCHAR(10)) + ' AND '		
		END
	ELSE 
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'LocationID IN ( SELECT B.ID AS ID FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
		END
	
	IF NOT @strInYear = ''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'DATEPART(year, AcquiredDate) = '+@strInYear+' AND '	
		END
		
	SET @strSQL = @strSQL + @strJoinSQL + ' WHERE ' +@strLikeSQL 
	SET @strSQL = LEFT(@strSQL,LEN(@strSQL)-3) 
	SET @strSQL = @strSQL + ' GROUP BY Month(AcquiredDate) ORDER BY MONTH ASC'
	--process here
EXEC(@strSQL)


go
/******/
Create PROCEDURE [dbo].[FPT_ACQ_YEAR_STATISTIC] 
	@intLibraryID int,
	@intLocationID int,
	@strFromYear varchar(4),
	@strToYear varchar(4),
	@intUserID int
AS
	DECLARE @strSQL varchar(1000)
	DECLARE @strJoinSQL varchar(1000)
	DECLARE @strLikeSql varchar(1000)
		
	SET @strSQL = 'SELECT YEAR(AcquiredDate) AS YEAR, Count(DISTINCT ItemID) AS BooksTotal, COUNT(*) AS CopiesTotal, 
    MoneyTotal = SUM(ISNULL(Price,0)) '
	SET @strJoinSQL = 'FROM HOLDING '
	SET @strLikeSql = '1 =1 AND '
	
	IF NOT @intLibraryID = 0
		BEGIN		
			IF NOT @intLocationID = 0
				SET @strLikeSQL = @strLikeSQL + 'LocationID = ' + CAST(@intLocationID AS VARCHAR(10)) +' AND '
			ELSE
				SET @strLikeSQL = @strLikeSQL + 'LibID = ' + CAST(@intLibraryID AS VARCHAR(10)) + ' AND '		
		END
	ELSE 
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'LocationID IN ( SELECT B.ID AS ID FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
		END
	
	IF NOT @strFromYear = ''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'DATEPART(year, AcquiredDate) >= '+@strFromYear+' AND '	
		END
		
	IF NOT @strToYear = ''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'DATEPART(year, AcquiredDate) <= '+@strToYear+' AND '	
		END
		
	SET @strSQL = @strSQL + @strJoinSQL + ' WHERE ' +@strLikeSQL 
	SET @strSQL = LEFT(@strSQL,LEN(@strSQL)-3) 
	SET @strSQL = @strSQL + ' GROUP BY YEAR(AcquiredDate) ORDER BY YEAR ASC'
	--process here
EXEC(@strSQL)

go
/******/
Create PROCEDURE [dbo].[FPT_BORROWNUMBER] (@itemID int, @price real, @acqdate varchar(50))
	-- Add the parameters for the stored procedure here
	
AS
DECLARE @sql varchar(1000)
SET @sql = ''+CONVERT (varchar(10), @acqdate, 21)
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SELECT COUNT(COPYNUMBER) FROM HOLDING WHERE ITEMID = @itemID AND PRICE = @price AND AcquiredDate = @sql
END


go
/******/
Create PROCEDURE [dbo].[FPT_CHECK_ITEMID_AND_ACQUIREDATE](@LocID int, @CDate date, @itemId int)
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	select ItemID  from Holding 
where AcquiredDate < CONVERT (varchar(10), @CDate, 21) and ItemID = @itemId and LocationID = @LocID
END

go
/******/
Create PROCEDURE [dbo].[FPT_CIR_GET_LOCFULLNAME_LIBUSER_SEL](@intUserID int,@intLibID int, @strLocPrefix nvarchar(3))
AS
	SELECT CODE + ':' + SYMBOL AS LOCNAME, B.ID AS ID, REPLACE(CAST(A.ID AS CHAR(3)) + ':' + CAST(B.ID AS CHAR(3)), ' ', '') AS GroupID, A.ID AS LibID, B.Symbol, A.Code
	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C 
	WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID = @intUserID AND B.LibID = @intLibID AND B.SYMBOL LIKE ''+@strLocPrefix+'%'
	ORDER BY B.LibID, B.Symbol


	go
/******/
Create PROCEDURE [dbo].[FPT_CIR_GET_LOCLIBUSER_PREFIX_SEL](@intUserID int,@intLibID int)
AS
	SELECT distinct(cast(B.Symbol as nvarchar(3))) as LocationCode
	FROM [Libol].[dbo].[HOLDING_LOCATION] B, HOLDING_LIBRARY A, SYS_USER_CIR_LOCATION C 
	WHERE LibID = @intLibID AND B.LIBID = A.ID AND C.LOCATIONID = B.ID AND C.USERID = @intUserID


	go
/******/
Create PROCEDURE [dbo].[FPT_CIR_MONTH_STATISTIC] 
@intLibraryID int,
@intLocationID int,
@intType int,
@intStatus int,
@strInYear varchar(4),
@intUserID int
AS
	DECLARE @strSQL varchar(1000)
	DECLARE @strJoinSQL varchar(1000)
	DECLARE @strLikeSql varchar(1000)	
	
	SET @strLikeSql = '1 =1 AND '
	SET @strJoinSQL = ''
	
	IF @intType = 1 -- Stat by ItemID
		SET @strSQL = 'SELECT TotalLoan = Count (distinct ITEMID)'
	
	IF @intType = 2 -- Stat by ID (CopyNumber)
		SET @strSQL = 'SELECT TotalLoan = Count (ID)'
		
	IF @intType = 3 -- Stat by PatronID
		SET @strSQL = 'SELECT TotalLoan = Count (distinct PATRONID)'
			
	SET @strSQL = @strSQL + ', MONTH = DATEPART(month, CheckOutDate) '	
		
	IF @intStatus = 0 -- Used
		SET @strJoinSQL = ' FROM CIR_LOAN_HISTORY'
	ELSE -- Using
		SET @strJoinSQL = ' FROM CIR_LOAN'
		
	IF NOT @intLibraryID = 0
		BEGIN		
			IF NOT @intLocationID = 0
				SET @strLikeSQL = @strLikeSQL + 'LocationID = '+ CAST(@intLocationID AS VARCHAR(10)) +' AND '
			ELSE
				SET @strLikeSQL = @strLikeSQL + 'LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ') AND '		
		END
	ELSE 
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
		END
	
	IF NOT @strInYear = ''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'DATEPART(year, CheckOutDate) = '+@strInYear+' AND '	
		END
		
		
	SET @strSQL = @strSQL + @strJoinSQL + ' WHERE ' +@strLikeSQL 
	SET @strSQL = LEFT(@strSQL,LEN(@strSQL)-3) 
	SET @strSQL = @strSQL + ' GROUP BY DATEPART(Month, CheckOutDate) ORDER BY MONTH ASC'
	--process here
EXEC(@strSQL)


go
/******/
Create PROCEDURE [dbo].[FPT_CIR_YEAR_STATISTIC] 
@intLibraryID int,
@intLocationID int,
@intType int,
@intStatus int,
@strFromYear varchar(4),
@strToYear varchar(4),
@intUserID int
AS
	DECLARE @strSQL varchar(1000)
	DECLARE @strJoinSQL varchar(1000)
	DECLARE @strLikeSql varchar(1000)
	
	SET @strLikeSql = '1 =1 AND '
	SET @strJoinSQL = ''	

	IF @intType = 1 -- Stat by ItemID
		SET @strSQL = 'SELECT TotalLoan = Count (distinct ITEMID)'
	
	IF @intType = 2 -- Stat by ID (CopyNumber)
		SET @strSQL = 'SELECT TotalLoan = Count (ID)'
		
	IF @intType = 3 -- Stat by PatronID
		SET @strSQL = 'SELECT TotalLoan = Count (distinct PATRONID)'
		
	SET @strSQL = @strSQL + ', Year = DATEPART(year, CheckOutDate) '	
			
	IF @intStatus = 0 -- Used
		SET @strJoinSQL = ' FROM CIR_LOAN_HISTORY'
	ELSE -- Using
		SET @strJoinSQL = ' FROM CIR_LOAN'
		
	IF NOT @intLibraryID = 0
		BEGIN		
			IF NOT @intLocationID = 0
				SET @strLikeSQL = @strLikeSQL + 'LocationID = '+ CAST(@intLocationID AS VARCHAR(10)) +' AND '
			ELSE
				SET @strLikeSQL = @strLikeSQL + 'LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ') AND '		
		END
	ELSE 
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
		END
	
	IF NOT @strFromYear = ''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'DATEPART(year, CheckOutDate) >= '+@strFromYear+' AND '	
		END
		
	IF NOT @strToYear = ''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'DATEPART(year, CheckOutDate) <= '+@strToYear+' AND '	
		END
		
	SET @strSQL = @strSQL + @strJoinSQL + ' WHERE ' +@strLikeSQL 
	SET @strSQL = LEFT(@strSQL,LEN(@strSQL)-3) 
	SET @strSQL = @strSQL + ' GROUP BY DATEPART(Year, CheckOutDate) ORDER BY Year ASC'
	--process here
EXEC(@strSQL)


go
/******/
Create PROCEDURE [dbo].[FPT_GET_LIQUIDBOOKS]
	@strLiquidCode VARCHAR(500),
	@intLibraryID int,
	@intLocationID int,
	@strDateFrom varchar(30),
	@strDateTo varchar(30),
	@intUserID int
AS

	DECLARE @strSQL VARCHAR(8000)
	DECLARE @strJoinSQL varchar(1000)
	DECLARE @strLikeSql varchar(1000)
	SET @strSQL = 'SELECT HRR.Reason,
	REPLACE(REPLACE(REPLACE(REPLACE(F.Content,''$a'',''''),''$b'','' ''),''$c'','' ''),''$n'','' '') as Content,
	HR.AcquiredSourceID,HR.CallNumber,HR.CopyNumber,
	HR.ID,HR.ItemID,HR.LibID,HR.LiquidCode,
	HR.LoanTypeID,HR.LocationID,HR.PoID,HR.Price,HR.Shelf,HR.UseCount,HR.Volume,
	HR.AcquiredDate,HR.RemovedDate,HR.DateLastUsed,
	Code AS LibName, Symbol AS LocName '
	
	SET @strLikeSql = '1 =1 AND '
	SET @strJoinSQL = ''
	
	SET @strJoinSQL = @strJoinSQL + ' FROM HOLDING_REMOVED HR LEFT JOIN FIELD200S F ON HR.ItemID = F.ItemID AND F.FieldCode=''245'' '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN HOLDING_REMOVE_REASON HRR ON HR.Reason=HRR.ID '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN HOLDING_LIBRARY HL ON HR.LibID = HL.ID '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN HOLDING_LOCATION HLC ON HR.LocationID = HLC.ID '
		
	IF NOT @strLiquidCode=''
		BEGIN
			SET @strLikeSql=@strLikeSql+' LiquidCode='''+@strLiquidCode+''' AND '
		END
	IF NOT @intLibraryID = 0
		BEGIN
			SET @strLikeSql = @strLikeSql + 'HR.LibID = ' + CAST(@intLibraryID AS VARCHAR(10)) +' AND '
			IF NOT @intLocationID = 0
				BEGIN
					SET @strLikeSql = @strLikeSql + 'HR.LocationID = ' + CAST(@intLocationID AS VARCHAR(10)) +' AND '
				END
			ELSE 
				BEGIN
					SET @strLikeSql = @strLikeSql + 'HR.LocationID IN (SELECT B.ID AS ID FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
				END
		END
	IF NOT @strDateFrom=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'HR.RemovedDate >= ''' + @strDateFrom +''' AND '	
		END
	IF NOT @strDateTo=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'HR.RemovedDate <= ''' + @strDateTo +''' AND '	
		END
	
	
	SET @strSql = @strSql + @strJoinSQL + ' WHERE ' +@strLikeSQL
	SET @strSql = LEFT(@strSql,LEN(@strSql)-3) 
EXEC(@strSQL)
PRINT(@strSQL)


go
/******/
Create PROCEDURE [dbo].[FPT_GET_LOCFULLNAME_LIBUSER_SEL](@intUserID int,@intLibID int, @strLocPrefix nvarchar(3))
AS
	SELECT CODE + ':' + SYMBOL AS LOCNAME, B.ID AS ID, REPLACE(CAST(A.ID AS CHAR(3)) + ':' + CAST(B.ID AS CHAR(3)), ' ', '') AS GroupID, A.ID AS LibID, B.Symbol, A.Code
	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_LOCATION C 
	WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocID AND C.UserID = @intUserID AND B.LibID = @intLibID AND B.SYMBOL LIKE ''+@strLocPrefix+'%'
	ORDER BY B.LibID, B.Symbol


go
/******/
Create   PROCEDURE [dbo].[FPT_GET_PATRON_LOANINFOR]
-- Purpose: Get patron on loan
-- Created Tuanhv
-- Date 05/09/2004
-- ModifyDate:

	@strPatronCode  varchar(50),
	@strItemCode  varchar(30),
	@strCopyNumber  varchar(30),
	@intLibraryID int,
	@strLocationPrefix varchar(5),
	@intLocationID  int,
	@strCheckOutDateFrom varchar(30),
	@strCheckOutDateTo varchar(30),
	@strCheckInDateFrom varchar(30),
	@strCheckInDateTo varchar(30),
	@strSerial nvarchar(50),
	@intUserID int
AS
	DECLARE @strSql varchar(1000)
	DECLARE @strJoinSQL varchar(1000)
	DECLARE @strLikeSql varchar(1000)
	DECLARE @strSelectedTabs varchar(500)
	SET @strSql = 'SELECT DISTINCT REPLACE(REPLACE(REPLACE(REPLACE(F.Content,''$a'',''''),''$b'','' ''),''$c'','' ''),''$n'','' '') as Content,CLH.CopyNumber,CLH.CheckOutDate,CLH.CheckInDate,CLH.RenewCount,CLH.Serial,isnull(CP.FirstName,'''') + '+''' '''+' + isnull(CP.MiddleName,'''') + '+''' ''' +' + isnull(CP.LastName,'''') + '+''' (''' + '+ CP.Code +' + ''')''' + 'as FullName, CLH.OverdueDays,CLH.OverdueFine, H.Price AS Price, H.Currency AS Currency '			
	SET @strLikeSql = '1 =1 AND '
	SET @strJoinSQL = ''


	SET @strJoinSQL = @strJoinSQL + ' FROM CIR_LOAN_HISTORY CLH LEFT JOIN CIR_PATRON CP ON CP.ID = CLH.PatronID '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN FIELD200S F ON CLH.ItemID=F.ItemID and F.FieldCode=''245'' '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN HOLDING H ON CLH.CopyNumber = H.CopyNumber '

	IF NOT @strItemCode='' 
		BEGIN
			SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN ITEM I ON CLH.ItemID=I.ID'
			SET @strLikeSql = @strLikeSql + 'UPPER(I.Code)='''+UPPER(@strItemCode)+''' AND '
		END

	IF NOT @strCopyNumber=''
		SET @strLikeSql=@strLikeSql + 'CLH.CopyNumber=''' + @strCopyNumber + ''' AND '

	IF NOT @strPatronCode =''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'UPPER(CP.Code)='''+ UPPER(@strPatronCode) +''' AND '
		END

	IF NOT @intLibraryID = 0
		BEGIN
			IF NOT @strLocationPrefix ='0'
				BEGIN			
					IF NOT @intLocationID = 0
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CLH.LocationID='+ CAST(@intLocationID AS VARCHAR(10)) +' AND '
						END
					ELSE
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CLH.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' AND B.Symbol LIKE '''+ @strLocationPrefix +'%'') AND '
						END
				END
			ELSE
				BEGIN
					SET @strLikeSQL = @strLikeSQL + 'CLH.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
				END
		END
	ELSE 
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CLH.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
		END
	

	IF NOT @strCheckOutDateFrom=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CLH.CheckOutDate >= '''+@strCheckOutDateFrom+''' AND '	
		END
	IF NOT @strCheckOutDateTo=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CLH.CheckOutDate <= '''+@strCheckOutDateTo+''' AND '	
		END
	IF NOT @strCheckInDateFrom=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CLH.CheckInDate >= ''' + @strCheckInDateFrom +''' AND '	
		END
	IF NOT @strCheckInDateTo=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CLH.CheckInDate <= ''' + @strCheckInDateTo + ''' AND '	
		END
	IF Not @strSerial=''
		SET @strLikeSQL = @strLikeSQL + 'UPPER(CLH.Serial)='''+ UPPER(@strSerial) +''' AND '
	SET @strSql = @strSql + @strJoinSQL + ' WHERE ' +@strLikeSQL
	SET @strSql = LEFT(@strSql,LEN(@strSql)-3) 
EXEC (@stRSql)
print(@stRSql)

go
/******/
Create   PROCEDURE [dbo].[FPT_GET_PATRON_ONLOANINFOR]
-- Purpose: Get patron on loan
-- Created Tuanhv
-- Date 31/08/2004
-- ModifyDate:

	@strPatronCode  varchar(50),
	@strItemCode  varchar(30),
	@strCopyNumber  varchar(30),
	@intLibraryID int,
	@strLocationPrefix varchar(5),
	@intLocationID  int,
	@strCheckOutDateFrom varchar(30),
	@strCheckOutDateTo varchar(30),
	@strDueDateFrom varchar(30),
	@strDueDateTo varchar(30),
	@strSerial nvarchar(50),
	@intUserID int
AS
	DECLARE @strSql varchar(1000)
	DECLARE @strJoinSQL varchar(1000)
	DECLARE @strLikeSql varchar(1000)
	DECLARE @strSelectedTabs varchar(500)
	SET @strSql = 'SELECT DISTINCT REPLACE(REPLACE(REPLACE(REPLACE(F.Content,''$a'',''''),''$b'','' ''),''$c'','' ''),''$n'','' '') as Content,CL.CopyNumber,CL.CheckOutDate ,CL.DueDate,CL.RenewCount,CL.Serial,isnull(CP.FirstName,'''') + '+''' '''+' + isnull(CP.MiddleName,'''') + '+''' ''' +' + isnull(CP.LastName,'''') + '+'''(''' + '+ CP.Code +' + ''')''' + 'as FullName, H.Price AS Price, H.Currency AS Currency '			
	SET @strLikeSql = '1 =1 AND '
	SET @strJoinSQL = ''


	SET @strJoinSQL = @strJoinSQL + ' FROM CIR_LOAN CL JOIN CIR_PATRON CP ON CP.ID = CL.PatronID '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN FIELD200S F ON CL.ItemID=F.ItemID and F.FieldCode=''245'''
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN HOLDING H ON CL.CopyNumber = H.CopyNumber '

	IF NOT @strItemCode='' 
		BEGIN
			SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN ITEM I ON CL.ItemID=I.ID'
			SET @strLikeSql = @strLikeSql + 'I.Code='''+@strItemCode+''' AND '
		END

	IF NOT @strCopyNumber=''
		SET @strLikeSql=@strLikeSql + 'CL.CopyNumber=''' + @strCopyNumber + ''' AND '

	IF NOT @strPatronCode =''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CP.Code='''+ @strPatronCode +''' AND '
		END

	IF NOT @intLibraryID = 0
		BEGIN
			IF NOT @strLocationPrefix ='0'
				BEGIN			
					IF NOT @intLocationID = 0
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CL.LocationID='+ CAST(@intLocationID AS VARCHAR(10)) +' AND '
						END
					ELSE
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CL.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' AND B.Symbol LIKE '''+ @strLocationPrefix +'%'') AND '
						END
				END
			ELSE
				BEGIN
					SET @strLikeSQL = @strLikeSQL + 'CL.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
				END
		END
	ELSE
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
		END	

	IF NOT @strCheckOutDateFrom=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.CheckOutDate >= '''+@strCheckOutDateFrom+''' AND '	
		END
	IF NOT @strCheckOutDateTo=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.CheckOutDate <= '''+@strCheckOutDateTo+''' AND '	
		END
	IF NOT @strDueDateFrom=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.DueDate >= ''' + @strDueDateFrom +''' AND '	
		END
	IF NOT @strDueDateTo=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.DueDate <= ''' + @strDueDateTo + ''' AND '	
		END
	IF NOT @strSerial=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.Serial='''+ @strSerial +''' AND '
		END
	SET @strSql = @strSql + @strJoinSQL + ' WHERE ' +@strLikeSQL
	SET @strSql = LEFT(@strSql,LEN(@strSql)-3) 
	EXEC (@stRSql)
	print(@stRSql)

	
go	
/******/
Create   PROCEDURE [dbo].[FPT_GET_PATRON_RENEW_LOAN_INFOR]
-- Purpose: Get patron renew
-- Created AnhTH
-- Date 05/10/2010
-- ModifyDate:
--- [GET_PATRON_RENEW_LOAN_INFOR] '','','','','','','','',0,1
	@strPatronCode  varchar(50),
	@strItemCode  varchar(30),
	@strCopyNumber  varchar(30),
	@intLibraryID  int,
	@strLocationPrefix varchar(5),
	@intLocationID  int,
	@strCheckOutDateFrom varchar(30),
	@strCheckOutDateTo varchar(30),
	@strCheckInDateFrom varchar(30),
	@strCheckInDateTo varchar(30),
	@intUserID int
AS
	DECLARE @strSql varchar(1000)
	DECLARE @strSql2 varchar(1000)
	DECLARE @strJoinSQL varchar(1000)
	DECLARE @strLikeSql varchar(1000)
	DECLARE @strSelectedTabs varchar(500)

BEGIN	
	SET @strSql = 'SELECT DISTINCT REPLACE(REPLACE(REPLACE(REPLACE(F.Content,''$a'',''''),''$b'','' ''),''$c'','' ''),''$n'','' '') as Content,CLH.CopyNumber,CLH.CheckOutDate, CLH.CheckInDate,isnull(CP.FirstName,'''') + '+''' '''+' + isnull(CP.MiddleName,'''') + '+''' ''' +' + isnull(CP.LastName,'''') + '+''' (''' + '+ CP.Code +' + ''')''' + 'as FullName, CR.RenewDate, CR.OverDueDateNew, CR.OverDueDateOld, CLH.OverdueDays, CLH.OverdueFine, H.Price AS Price, H.Currency AS Currency '			
	SET @strLikeSql = '1 =1 AND '
	SET @strJoinSQL = ''


	SET @strJoinSQL = @strJoinSQL + ' FROM CIR_LOAN_HISTORY CLH LEFT JOIN CIR_PATRON CP ON CP.ID = CLH.PatronID '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN FIELD200S F ON CLH.ItemID=F.ItemID and F.FieldCode=''245'''
	SET @strJoinSQL = @strJoinSQL + ' RIGHT JOIN CIR_RENEW CR ON CLH.ID = CR.CirLoanHisID '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN HOLDING H ON CLH.CopyNumber = H.CopyNumber '
	
	IF NOT @strItemCode='' 
		BEGIN
			SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN ITEM I ON CLH.ItemID=I.ID'
			SET @strLikeSql = @strLikeSql + 'UPPER(I.Code)='''+UPPER(@strItemCode)+''' AND '
		END

	IF NOT @strCopyNumber=''
		SET @strLikeSql=@strLikeSql + 'CLH.CopyNumber=''' + @strCopyNumber + ''' AND '

	IF NOT @strPatronCode =''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'UPPER(CP.Code)='''+ UPPER(@strPatronCode) +''' AND '
		END
		
	IF NOT @intLibraryID = 0
		BEGIN
			IF NOT @strLocationPrefix ='0'
				BEGIN			
					IF NOT @intLocationID = 0
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CLH.LocationID='+ CAST(@intLocationID AS VARCHAR(10)) +' AND '
						END
					ELSE
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CLH.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' AND B.Symbol LIKE '''+ @strLocationPrefix +'%'') AND '
						END
				END
			ELSE
				BEGIN
					SET @strLikeSQL = @strLikeSQL + 'CLH.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
				END
		END
	ELSE 
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CLH.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
		END	

	IF NOT @strCheckOutDateFrom=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CLH.CheckOutDate >= '''+@strCheckOutDateFrom+''' AND '	
		END
	IF NOT @strCheckOutDateTo=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CLH.CheckOutDate <= '''+@strCheckOutDateTo+''' AND '	
		END
	IF NOT @strCheckInDateFrom=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CLH.CheckInDate >= ''' + @strCheckInDateFrom +''' AND '	
		END
	IF NOT @strCheckInDateTo=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CLH.CheckInDate <= ''' + @strCheckInDateTo + ''' AND '	
		END
	--IF Not @strSerial=''
		--SET @strLikeSQL = @strLikeSQL + 'UPPER(CLH.Serial)='''+ UPPER(@strSerial) +''' AND '
	SET @strSql = @strSql + @strJoinSQL + ' WHERE ' +@strLikeSQL
	SET @strSql = LEFT(@strSql,LEN(@strSql)-3) 
	PRINT '1'
END
	EXEC(@strSql)
PRINT (@strSql)


go
/******/
Create   PROCEDURE [dbo].[FPT_GET_PATRON_RENEW_ONLOAN_INFOR]
-- Purpose: Get patron renew
-- Created AnhTH
-- Date 05/10/2010
-- ModifyDate:
--- [GET_PATRON_RENEW_ONLOAN_INFOR] '','','','','','','','',0,1
	@strPatronCode  varchar(50),
	@strItemCode  varchar(30),
	@strCopyNumber  varchar(30),
	@intLibraryID  int,
	@strLocationPrefix varchar(5),
	@intLocationID  int,
	@strCheckOutDateFrom varchar(30),
	@strCheckOutDateTo varchar(30),
	@strCheckInDateFrom varchar(30),
	@strCheckInDateTo varchar(30),
	@intUserID int
AS
	DECLARE @strSql varchar(1000)
	DECLARE @strSql2 varchar(1000)
	DECLARE @strJoinSQL varchar(1000)
	DECLARE @strLikeSql varchar(1000)
	DECLARE @strSelectedTabs varchar(500)

BEGIN	
	SET @strSql = 'SELECT DISTINCT REPLACE(REPLACE(REPLACE(REPLACE(F.Content,''$a'',''''),''$b'','' ''),''$c'','' ''),''$n'','' '') as Content,CL.CopyNumber,CL.CheckOutDate, CL.DueDate,isnull(CP.FirstName,'''') + '+''' '''+' + isnull(CP.MiddleName,'''') + '+''' ''' +' + isnull(CP.LastName,'''') + '+''' (''' + '+ CP.Code +' + ''')''' + 'as FullName, CR.RenewDate, CR.OverDueDateNew, CR.OverDueDateOld, H.Price AS Price, H.Currency AS Currency '			
	SET @strLikeSql = '1 =1 AND '
	SET @strJoinSQL = ''


	SET @strJoinSQL = @strJoinSQL + ' FROM CIR_LOAN CL LEFT JOIN CIR_PATRON CP ON CP.ID = CL.PatronID '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN FIELD200S F ON CL.ItemID=F.ItemID and F.FieldCode=''245'''
	SET @strJoinSQL = @strJoinSQL + ' RIGHT JOIN CIR_RENEW CR ON CL.ID = CR.CirLoanID '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN HOLDING H ON CL.CopyNumber = H.CopyNumber '
	
	IF NOT @strItemCode='' 
		BEGIN
			SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN ITEM I ON CL.ItemID=I.ID'
			SET @strLikeSql = @strLikeSql + 'UPPER(I.Code)='''+UPPER(@strItemCode)+''' AND '
		END

	IF NOT @strCopyNumber=''
		SET @strLikeSql=@strLikeSql + 'CL.CopyNumber=''' + @strCopyNumber + ''' AND '

	IF NOT @strPatronCode =''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'UPPER(CP.Code)='''+ UPPER(@strPatronCode) +''' AND '
		END

	IF NOT @intLibraryID = 0
		BEGIN
			IF NOT @strLocationPrefix ='0'
				BEGIN			
					IF NOT @intLocationID = 0
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CL.LocationID='+ CAST(@intLocationID AS VARCHAR(10)) +' AND '
						END
					ELSE
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CL.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' AND B.Symbol LIKE '''+ @strLocationPrefix +'%'') AND '
						END
				END
			ELSE
				BEGIN
					SET @strLikeSQL = @strLikeSQL + 'CL.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID ='+ CAST(@intLibraryID AS CHAR(20)) +' AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
				END
		END
	ELSE
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.LocationID IN ( SELECT B.ID AS ID 	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) AND '
		END

	IF NOT @strCheckOutDateFrom=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.CheckOutDate >= '''+@strCheckOutDateFrom+''' AND '	
		END
	IF NOT @strCheckOutDateTo=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.CheckOutDate <= '''+@strCheckOutDateTo+''' AND '	
		END
	IF NOT @strCheckInDateFrom=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.CheckInDate >= ''' + @strCheckInDateFrom +''' AND '	
		END
	IF NOT @strCheckInDateTo=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.CheckInDate <= ''' + @strCheckInDateTo + ''' AND '	
		END
	--IF Not @strSerial=''
		--SET @strLikeSQL = @strLikeSQL + 'UPPER(CL.Serial)='''+ UPPER(@strSerial) +''' AND '
	SET @strSql = @strSql + @strJoinSQL + ' WHERE ' +@strLikeSQL
	SET @strSql = LEFT(@strSql,LEN(@strSql)-3) 
	PRINT '1'
END
	EXEC(@strSql)
PRINT (@strSql)


go
/******/
Create PROCEDURE [dbo].[FPT_JOIN_ISBN] (@itemid int)
	-- Add the parameters for the stored procedure here
AS
BEGIN
	SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
WHERE ITEMID = @itemid
GROUP BY ItemID

END


go
/******/
Create PROCEDURE [dbo].[FPT_SELECT_USECOUNT2] (@LibID int, @itemID int, @cDate date)
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
SELECT USECOUNT FROM HOLDING WHERE ItemID = @itemID and LIBID = @LibID and ACQUIREDDATE = @cDate
END


go
/******/
Create PROCEDURE [dbo].[FPT_SP_CIR_LIBLOCUSER_SEL](@intUserID int,@intLibID int)
AS
	SELECT CODE + ':' + SYMBOL AS LOCNAME, B.ID AS ID, REPLACE(CAST(A.ID AS CHAR(3)) + ':' + CAST(B.ID AS CHAR(3)), ' ', '') AS GroupID, A.ID AS LibID, B.Symbol, A.Code
	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C 
	WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID = @intUserID AND B.LibID = @intLibID
	ORDER BY B.LibID, B.Symbol


go	
/******/
Create PROCEDURE [dbo].[FPT_SP_GET_COPYNUMBER_STRING] (@libid int, @acqdate varchar(50), @price real, @itemid int)
AS
DECLARE @sql varchar(50)
SET @sql = ''+CONVERT (varchar(10), @acqdate, 21)
BEGIN
	SELECT distinct ItemID,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID and LibID = @libid and Price = @price AND AcquiredDate = @sql
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
where D2.ItemID =@itemid
END


go
/******/
Create PROCEDURE [dbo].[FPT_SP_GET_HOLDING_BY_LOCATIONID_lan12] (@LibID int, @LocID int, @POID int, @StartDate date, @EndDate date, @OrderBy varchar(10))
AS
if @LocID =0 or @LocID is null
BEGIN
if @OrderBy = 'asc'
	BEGIN
	
		if @StartDate is null AND @EndDate is null AND @POID is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END	
		ELSE IF @StartDate is null AND @EndDate is null AND @POID is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID and F.FieldCode = 245 and A.POID =@POID
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @POID is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is null AND @POID is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is not null AND @POID is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is null AND @POID is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and A.POID=@POID
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @POID is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and A.POID=@POID
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is not null AND @POID is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung,A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
			AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and A.POID=@POID
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
	END
	------------------------
	ELSE IF @OrderBy = 'desc'
	BEGIN
	if @StartDate is null AND @EndDate is null AND @POID is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END	
	ELSE IF @StartDate is null AND @EndDate is null AND @POID is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung,A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID and F.FieldCode = 245 and A.POID=@POID
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @POID is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung,A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is null AND @POID is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung,A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is not null AND @POID is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is null AND @POID is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung,A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and A.POID=@POID
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @POID is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and A.POID=@POID
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is not null AND @POID is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
		AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and A.POID=@POID
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
END
	
END
--- CHECK LocID---------------------------------------------
else
BEGIN
if @OrderBy = 'asc'
	BEGIN
	
		if @StartDate is null AND @EndDate is null AND @POID is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END	
		ELSE IF @StartDate is null AND @EndDate is null AND @POID is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID and F.FieldCode = 245 and A.POID =@POID
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @POID is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is null AND @POID is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is not null AND @POID is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is null AND @POID is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and A.POID=@POID
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @POID is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and A.POID=@POID
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is not null AND @POID is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung,A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
			AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and A.POID=@POID
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
	END
	------------------------
	ELSE IF @OrderBy = 'desc'
	BEGIN
	if @StartDate is null AND @EndDate is null AND @POID is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END	
	ELSE IF @StartDate is null AND @EndDate is null AND @POID is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung,A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID and F.FieldCode = 245 and A.POID=@POID
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @POID is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung,A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is null AND @POID is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung,A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is not null AND @POID is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is null AND @POID is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung,A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and A.POID=@POID
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @POID is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and A.POID=@POID
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is not null AND @POID is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				B.ISBN, cast(A.ReceiptedDate as Date) AS NgayChungTu, 
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join (SELECT ItemID ,
STUFF(( SELECT Distinct  ', ' + Number
FROM CAT_DIC_NUMBER C1
WHERE C1.ItemID = C2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS ISBN
FROM CAT_DIC_NUMBER C2
GROUP BY ItemID) as B on A.ItemID = B.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
		AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and A.POID=@POID
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
END
	
END

go
/******/
Create PROCEDURE [dbo].[FPT_SP_GET_HOLDING_BY_RECOMMEND_LAN3] (@LibID int, @LocID int, @reid varchar(30), @StartDate date, @EndDate date, @OrderBy varchar(10))
AS
if @LocID =0 or @LocID is null
BEGIN
if @OrderBy = 'asc'
	BEGIN
	
		if @StartDate is null AND @EndDate is null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END	
		ELSE IF @StartDate is null AND @EndDate is null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID and F.FieldCode = 245 and T.REID =@reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and T.REID = @reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and T.REID = @reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
			AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and T.REID = @reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
	END
	------------------------
	ELSE IF @OrderBy = 'desc'
	BEGIN
	if @StartDate is null AND @EndDate is null AND @reid is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END	
	ELSE IF @StartDate is null AND @EndDate is null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID and F.FieldCode = 245 and T.REID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @reid is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is null AND @reid is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and T.REID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and T.REID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
		AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and T.REID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
END
	
END
--- CHECK LocID---------------------------------------------
else
BEGIN
if @OrderBy = 'asc'
	BEGIN
	
		if @StartDate is null AND @EndDate is null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END	
		ELSE IF @StartDate is null AND @EndDate is null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID and F.FieldCode = 245 and T.REID =@reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and T.REID = @reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and T.REID = @reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
			AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and T.REID = @reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
	END
	------------------------
	ELSE IF @OrderBy = 'desc'
	BEGIN
	if @StartDate is null AND @EndDate is null AND @reid is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END	
	ELSE IF @StartDate is null AND @EndDate is null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID and F.FieldCode = 245 and T.REID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @reid is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is null AND @reid is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and T.REID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and T.REID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.POID, A.LocationID, T.REID,
				C.Year as NamXuatBan, A.Price as DonGia, REPLACE(A.Currency,' ','') as DonViTienTe, R.NXB as IdNhaXuatBan, U.ItemID
			FROM HOLDING A
			join (SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
GROUP BY ItemID) as U on A.ItemID = U.ItemID
			
			join FIELD200S F  on A.ItemID = F.ItemID
			join CAT_DIC_YEAR C on A.ItemID = C.ItemID
			JOIN FPT_RECOMMEND T ON A.POID = T.POID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
		AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and T.REID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
END
	
END

go
/******/
Create PROCEDURE [dbo].[FPT_SP_JOIN_COPYNUMBER_BY_ITEMID_AND_ACQUIREDDATE] (@ItemID int, @AcqDate Date)
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SELECT distinct ItemID ,
STUFF(( SELECT  ', ' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID AND D1.ACQUIREDDATE = CONVERT (varchar(10), @AcqDate, 21) AND D1.ItemID = @ItemID
FOR
XML PATH('')
), 1, 1, '') AS DKCB
FROM HOLDING D2
where D2.ItemID = @ItemID
GROUP BY ItemID
END

go
/******/
Create PROCEDURE [dbo].[SP_HOLDING_LIBLOCUSER_SEL](@intUserID int,@intLibID int)
AS
	SELECT CODE + ':' + SYMBOL AS LOCNAME, B.ID AS ID, REPLACE(CAST(A.ID AS CHAR(3)) + ':' + CAST(B.ID AS CHAR(3)), ' ', '') AS GroupID, A.ID AS LibID, B.Symbol, A.Code
	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_LOCATION C 
	WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocID AND C.UserID = @intUserID AND B.LibID = @intLibID
	ORDER BY B.LibID, B.Symbol

go
/******/
CREATE PROCEDURE [dbo].[FPT_ADMIN_GET_RIGHTS_DENY_ADMIN]
	@intModuleID int
AS

SELECT R.ID, R.[Right] FROM SYS_USER_RIGHT R 
WHERE R.ModuleID = @intModuleID AND R.ID 
NOT IN (
	SELECT U.ID FROM SYS_USER_RIGHT_DETAIL D JOIN SYS_USER_RIGHT U ON D.RightID = U.ID
	WHERE D.UserID = 1 AND U.ModuleID = @intModuleID
)