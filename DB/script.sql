﻿go
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

GO
/******/
CREATE TABLE FPT_SYS_USER_RIGHT(
	[ID] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[ModuleID] [int] NOT NULL,
	[Right] [nvarchar](100) NOT NULL,
	[IsBasic] [bit] NOT NULL
)
GO
/******/

CREATE TABLE FPT_SYS_USER_RIGHT_DETAIL(
	[RightID] [int] NOT NULL FOREIGN KEY REFERENCES FPT_SYS_USER_RIGHT(ID),
	[UserID] [int] NOT NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY	
)
GO
/******/

CREATE PROCEDURE [dbo].[FPT_SP_ADMIN_GRANT_RIGHTS]
	@intUID int,
	@intRightID int
AS
	INSERT INTO FPT_SYS_USER_RIGHT_DETAIL (UserID, RightID) VALUES (@intUID,@intRightID)
GO
/******/


CREATE  PROCEDURE [dbo].[FPT_SP_ADMIN_UPDATE_USER]
	@intUID int,
	@intISLDAP int,
	@strName NVarchar(100),
	@strUserName varchar(100),
	@strPassword varchar(100),
	@intCatModule int,
	@intPatModule int,
	@intCirModule int,
	@intAcqModule int,
	@intSerModule int,
	@intILLModule int,
	@intDelModule int,
	@intAdmModule int,
	@intParentID int,
	@intOutVal int OUT
AS
	DECLARE @strUserNameTemp varchar(100)
	DECLARE @strLDAPAdsPath varchar(100)

	SET @intOutVal = 0

	SELECT @strUserNameTemp = UserName FROM SYS_USER Where ID = @intUID
	SELECT @strLDAPAdsPath = ISNULL(LDAPAdsPath, '') FROM SYS_USER WHERE ID = @intUID 
	IF @strUserNameTemp = 'Admin'
		SET @strUserName = 'Admin'
	ELSE
	   BEGIN
	   	IF @intISLDAP = 0
			SELECT @intOutVal = ISNULL(Count(UserName),0) FROM SYS_USER WHERE UserName = @strUserName AND ID <> @intUID	
		ELSE
			SELECT @intOutVal = ISNULL(Count(UserName),0) FROM SYS_USER WHERE UserName = @strUserName AND ID <> @intUID AND LDAPAdsPath = @strLDAPAdsPath
	   END 	

	IF @intOutVal = 0 
	   BEGIN
		IF @strPassword <> '' 
			UPDATE SYS_USER SET Name = @strName,
			        Username = @strUserName, Password = @strPassword,
				Priority = @intCatModule ,AcqModule= @intAcqModule, 
				SerModule= @intSerModule , CirModule = @intCirModule,
				PatModule= @intPatModule, CatModule= @intCatModule,
				ILLModule= @intILLModule, DelModule= @intDelModule, 
				AdmModule = @intAdmModule, ParentID = @intParentID 
				WHERE ID = @intUID
		ELSE
			UPDATE SYS_USER SET Name = @strName,
			        Username = @strUserName,
				Priority = @intCatModule,AcqModule= @intAcqModule, 
				SerModule= @intSerModule , CirModule = @intCirModule,
				PatModule= @intPatModule,CatModule= @intCatModule  ,
				ILLModule= @intILLModule, DelModule= @intDelModule, 
				AdmModule = @intAdmModule, ParentID = @intParentID 
				WHERE ID = @intUID

		DELETE FROM FPT_SYS_USER_RIGHT_DETAIL WHERE UserID = @intUID
		DELETE FROM SYS_USER_LOCATION WHERE UserID = @intUID
		DELETE FROM SYS_USER_CIR_LOCATION WHERE UserID = @intUID
		DELETE FROM SYS_USER_SER_LOCATION WHERE UserID = @intUID
	   END
GO


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
SELECT R.ID, R.[Right] FROM FPT_SYS_USER_RIGHT_DETAIL D JOIN FPT_SYS_USER_RIGHT R ON D.RightID = R.ID
WHERE D.UserID = @intUserID AND R.ModuleID = @intModuleID

go
/******/
CREATE PROCEDURE [dbo].[FPT_ADMIN_GET_RIGHTS_DENY]
	@intModuleID int,
	@intUserID int,
	@intUserParentID int
AS

SELECT R.ID, R.[Right] FROM FPT_SYS_USER_RIGHT R 
JOIN FPT_SYS_USER_RIGHT_DETAIL D ON R.ID = D.RightID 
WHERE R.ModuleID = @intModuleID AND D.UserID = @intUserParentID AND R.ID 
NOT IN (
	SELECT U.ID FROM FPT_SYS_USER_RIGHT_DETAIL D JOIN FPT_SYS_USER_RIGHT U ON D.RightID = U.ID
	WHERE D.UserID = @intUserID AND U.ModuleID = @intModuleID
)

go
/******/
CREATE PROCEDURE [dbo].[FPT_ADMIN_GET_RIGHTS_WHEN_CREATE]
	@intModuleID int,
	@intParentID int,
	@IsBasic int
AS

SELECT R.ID, R.[Right] FROM FPT_SYS_USER_RIGHT R 
JOIN FPT_SYS_USER_RIGHT_DETAIL D ON R.ID = D.RightID 
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
	@intLocationID  varchar(500),
	@strCheckOutDateFrom varchar(30),
	@strCheckOutDateTo varchar(30),
	@strCheckInDateFrom varchar(30),
	@strCheckInDateTo varchar(30),
	@strSerial nvarchar(50),
	@intUserID int
AS
	DECLARE @strSql varchar(2000)
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
					IF NOT @intLocationID = ''
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CLH.LocationID IN ('+ @intLocationID +') AND '
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
	@intLocationID  varchar(500),
	@strCheckOutDateFrom varchar(30),
	@strCheckOutDateTo varchar(30),
	@strDueDateFrom varchar(30),
	@strDueDateTo varchar(30),
	@strSerial nvarchar(50),
	@intUserID int
AS
	DECLARE @strSql varchar(2000)
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
					IF NOT @intLocationID = ''
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CL.LocationID IN ('+ @intLocationID +') AND '
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
	@intLocationID  varchar(500),
	@strCheckOutDateFrom varchar(30),
	@strCheckOutDateTo varchar(30),
	@strCheckInDateFrom varchar(30),
	@strCheckInDateTo varchar(30),
	@intUserID int
AS
	DECLARE @strSql varchar(2000)
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
					IF NOT @intLocationID = ''
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CLH.LocationID IN ('+ @intLocationID +') AND '
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
	@intLocationID  varchar(500),
	@strCheckOutDateFrom varchar(30),
	@strCheckOutDateTo varchar(30),
	@strCheckInDateFrom varchar(30),
	@strCheckInDateTo varchar(30),
	@intUserID int
AS
	DECLARE @strSql varchar(2000)
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
					IF NOT @intLocationID = ''
						BEGIN
							SET @strLikeSQL = @strLikeSQL + 'CL.LocationID IN ('+ @intLocationID +') AND '
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
			SET @strLikeSQL = @strLikeSQL + 'CL.DueDate >= ''' + @strCheckInDateFrom +''' AND '	
		END
	IF NOT @strCheckInDateTo=''
		BEGIN
			SET @strLikeSQL = @strLikeSQL + 'CL.DueDate <= ''' + @strCheckInDateTo + ''' AND '	
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
	SELECT CODE + ':' + SYMBOL AS LOCNAME, B.ID AS ID, REPLACE(CAST(A.ID AS CHAR(3)) + ':' + CAST(B.ID AS CHAR(3)), ' ', '') AS GroupID, 
	A.ID AS LibID, B.Symbol, A.Code
	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_LOCATION C 
	WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocID AND C.UserID = @intUserID AND B.LibID = @intLibID
	ORDER BY B.LibID, B.Symbol




go
/******/
CREATE PROCEDURE [dbo].[FPT_ADMIN_GET_RIGHTS_DENY_ADMIN]
	@intModuleID int
AS

SELECT R.ID, R.[Right] FROM FPT_SYS_USER_RIGHT R 
WHERE R.ModuleID = @intModuleID AND R.ID 
NOT IN (
	SELECT U.ID FROM FPT_SYS_USER_RIGHT_DETAIL D JOIN FPT_SYS_USER_RIGHT U ON D.RightID = U.ID
	WHERE D.UserID = 1 AND U.ModuleID = @intModuleID
)




GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_CIR_LIB_SEL]    Script Date: 07/10/2019 23:47:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[FPT_SP_CIR_LIB_SEL]
	@intUserID  int
AS	
	SELECT Code + ': ' + Name as LibName, Code, ID 
	FROM HOLDING_LIBRARY 
	WHERE LocalLib = 1 AND ID IN (SELECT LibID FROM HOLDING_LOCATION, SYS_USER_CIR_LOCATION WHERE SYS_USER_CIR_LOCATION.LocationID = HOLDING_LOCATION.ID AND UserID = @intUserID) ORDER BY Code


GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_CATA_CHECK_EXIST_ITEMNUMBER]    Script Date: 7/1/2019 3:03:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[FPT_SP_CATA_CHECK_EXIST_ITEMNUMBER]
-- Purpose: Check exist item by ISBN or ISSN
-- MODIFICATION HISTORY
-- Person      Date    Comments
-- Oanhtn      090305  Create
-- ---------   ------  -------------------------------------------
	@strFieldValue	varchar(50),
	@strFieldCode	varchar(5),
	@lngItemID	int OUT

AS
	SELECT @lngItemID = ItemID FROM CAT_DIC_NUMBER WHERE FieldCode = @strFieldCode AND Number = @strFieldValue
	IF @lngItemID IS NULL SET @lngItemID = 0
	RETURN @lngItemID


/******/
GO
CREATE  PROCEDURE [dbo].[FPT_SP_CATA_GET_DETAILINFOR_OF_ITEM]  
-- Purpose: get all detail information of item (field's values)  
-- MODIFICATION HISTORY  
-- Person      Date    Comments  
-- DOANHDQ    04/07/2019    get all detail information of item (field's values)  
-- ---------   ------  -------------------------------------------  
@strItemIDs VARCHAR(2000),  
@intIsAuthority INT  
-- Declare program variables as shown above  
AS  
DECLARE @strSQL VARCHAR(8000)  
	IF @intIsAuthority = 0  
	BEGIN  
		SET @strItemIDs=REPLACE(@strItemIDs,'','')  
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, FIELD000s.ItemID AS ItemID, Ind1, Ind2, Content, VietFieldName  FROM MARC_BIB_FIELD, FIELD000s WHERE FIELD000s.ItemID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = FIELD000s.FieldCode UNION   
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, FIELD100s.ItemID AS ItemID, Ind1, Ind2, Content, VietFieldName  FROM MARC_BIB_FIELD, FIELD100s WHERE FIELD100s.ItemID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = FIELD100s.FieldCode UNION  
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, FIELD200s.ItemID AS ItemID, Ind1, Ind2, Content, VietFieldName  FROM MARC_BIB_FIELD, FIELD200s WHERE FIELD200s.ItemID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = FIELD200s.FieldCode UNION   
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, FIELD300s.ItemID AS ItemID, Ind1, Ind2, Content, VietFieldName  FROM MARC_BIB_FIELD, FIELD300s WHERE FIELD300s.ItemID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = FIELD300s.FieldCode UNION   
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, FIELD400s.ItemID AS ItemID, Ind1, Ind2, Content, VietFieldName  FROM MARC_BIB_FIELD, FIELD400s WHERE FIELD400s.ItemID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = FIELD400s.FieldCode UNION  
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, FIELD500s.ItemID AS ItemID, Ind1, Ind2, Content, VietFieldName  FROM MARC_BIB_FIELD, FIELD500s WHERE FIELD500s.ItemID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = FIELD500s.FieldCode UNION   
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, FIELD600s.ItemID AS ItemID, Ind1, Ind2, Content, VietFieldName  FROM MARC_BIB_FIELD, FIELD600s WHERE FIELD600s.ItemID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = FIELD600s.FieldCode UNION   
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, FIELD700s.ItemID AS ItemID, Ind1, Ind2, Content, VietFieldName  FROM MARC_BIB_FIELD, FIELD700s WHERE FIELD700s.ItemID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = FIELD700s.FieldCode UNION   
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, FIELD800s.ItemID AS ItemID, Ind1, Ind2, Content, VietFieldName  FROM MARC_BIB_FIELD, FIELD800s WHERE FIELD800s.ItemID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = FIELD800s.FieldCode UNION  
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, FIELD900s.ItemID AS ItemID, Ind1, Ind2, Content, VietFieldName  FROM MARC_BIB_FIELD, FIELD900s WHERE FIELD900s.ItemID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = FIELD900s.FieldCode UNION 
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, Item.ID AS ItemID, '' Ind1, '' Ind2, CAST(Item.NewRecord as varchar(5)) as Content, VietFieldName  FROM MARC_BIB_FIELD, ITEM WHERE Item.ID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = '900' UNION 
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, Item.ID AS ItemID, '' Ind1, '' Ind2, Item.CoverPicture as Content, VietFieldName  FROM MARC_BIB_FIELD, ITEM WHERE Item.ID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = '907' AND CoverPicture IS NOT NULL AND CoverPicture <>'' UNION 
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, Item.ID AS ItemID, '' Ind1, '' Ind2, Item.Cataloguer as Content, VietFieldName  FROM MARC_BIB_FIELD, ITEM WHERE Item.ID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = '911' AND  Cataloguer  IS NOT NULL AND Cataloguer <> '' UNION 
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, Item.ID AS ItemID, '' Ind1, '' Ind2, Item.Code as Content, VietFieldName  FROM MARC_BIB_FIELD, ITEM WHERE Item.ID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = '001' AND  Code  IS NOT NULL AND Code <> '' UNION 
		SELECT VietIndicators, Indicators, MARC_BIB_FIELD.FieldCode, Item.ID AS ItemID, '' Ind1, '' Ind2, Item.Reviewer as Content, VietFieldName  FROM MARC_BIB_FIELD, ITEM WHERE Item.ID IN (@strItemIDs) AND MARC_BIB_FIELD.FieldCode = '912' AND Reviewer IS NOT NULL AND Reviewer <> ''       
         ORDER BY ItemID, MARC_BIB_FIELD.FieldCode		
		
	END  
	ELSE SELECT NULL AS VietIndicators, NULL AS Indicators, FieldCode, AuthorityID AS ItemID, Ind1, Ind2, Content, '' as VietFieldName  FROM FIELD_AUTHORITY  WHERE AuthorityID IN( @strItemIDs ) ORDER BY AuthorityID, FieldCode

GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_UPDATE_UNLOCK_PATRON_CARD]  Script Date: 7/22/2019 7:22:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[FPT_SP_UPDATE_UNLOCK_PATRON_CARD]
-- Purpose: Update Unlock Locked PatronCard
-- MODIFICATION HISTORY
-- Person      Date    Comments
-- Trinhlv      300804  Create
-- ---------   ------  -------------------------------------------       
	@strPatronCode varchar(500),
	@lockedDay int,
	@Note nvarchar(1000)
AS
	UPDATE [CIR_PATRON_LOCK] SET LockedDays = @lockedDay, Note = @Note WHERE PatronCode = @strPatronCode



GO
/****** Object:  Table [dbo].[FPT_RECOMMEND]    Script Date: 7/13/2019 5:03:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FPT_RECOMMEND](
	[RecommendID] [varchar](50) NOT NULL,
 CONSTRAINT [PK_FPT_RECOMMEND] PRIMARY KEY CLUSTERED 
(
	[RecommendID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FPT_RECOMMEND_ITEM]    Script Date: 7/13/2019 5:03:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FPT_RECOMMEND_ITEM](
	[RecommendID] [varchar](50) NOT NULL,
	[ItemID] [int] NOT NULL,
 CONSTRAINT [PK_FK_FPT_RecommendID_ItemID] PRIMARY KEY CLUSTERED 
(
	[RecommendID] ASC,
	[ItemID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FPT_RECOMMEND_ITEM]  WITH CHECK ADD  CONSTRAINT [FK_FPT_RECOMMEND_Item_FPT_RECOMMEND] FOREIGN KEY([RecommendID])
REFERENCES [dbo].[FPT_RECOMMEND] ([RecommendID])
GO
ALTER TABLE [dbo].[FPT_RECOMMEND_ITEM] CHECK CONSTRAINT [FK_FPT_RECOMMEND_Item_FPT_RECOMMEND]
GO
ALTER TABLE [dbo].[FPT_RECOMMEND_ITEM]  WITH CHECK ADD  CONSTRAINT [FK_FPT_RECOMMEND_Item_ITEM] FOREIGN KEY([ItemID])
REFERENCES [dbo].[ITEM] ([ID])
GO
ALTER TABLE [dbo].[FPT_RECOMMEND_ITEM] CHECK CONSTRAINT [FK_FPT_RECOMMEND_Item_ITEM]
GO

GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_HOLDING_BY_RECOMMENDID]    Script Date: 07/23/2019 09:30:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,DucNV>
-- Create date: <16/06/2019,,>
-- Description:	<get data for 'Bao cao danh muc sach nhap' function,,>
-- =============================================
create PROCEDURE [dbo].[FPT_SP_GET_HOLDING_BY_RECOMMENDID] (@LibID int, @LocID int, @reid varchar(50), @StartDate date, @EndDate date, @OrderBy varchar(10))
AS
if @LocID =0 or @LocID is null
BEGIN
if @OrderBy = 'asc'
	BEGIN
	
		if @StartDate is null AND @EndDate is null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID and F.FieldCode = 245 and T.RECOMMENDID =@reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and T.RECOMMENDID = @reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and T.RECOMMENDID = @reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
			AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and T.RECOMMENDID = @reid
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID and F.FieldCode = 245 and T.RECOMMENDID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @reid is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and T.RECOMMENDID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and T.RECOMMENDID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LibID = @LibID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
		AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and T.RECOMMENDID = @reid
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID and F.FieldCode = 245 and T.RECOMMENDID =@reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @reid is null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and T.RECOMMENDID = @reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is null AND @EndDate is not null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and T.RECOMMENDID = @reid
			ORDER BY NgayBoSung ASC, U.DKCB asc
		END
		ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is not null
		BEGIN
			SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
			WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
			AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and T.RECOMMENDID = @reid
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID and F.FieldCode = 245 and T.RECOMMENDID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @reid is null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
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
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) and F.FieldCode = 245 and T.RECOMMENDID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is null AND @EndDate is not null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21)and F.FieldCode = 245 and T.RECOMMENDID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
	ELSE IF @StartDate is not null AND @EndDate is not null AND @reid is not null
	BEGIN
		SELECT distinct  A.RECORDNUMBER AS SoChungTu, REPLACE(REPLACE(REPLACE(REPLACE(F.Content,'$a',''),'$b',''),'$c',''),'$n','') as NhanDe, 
				 cast(A.ReceiptedDate as Date) AS NgayChungTu,
				U.DKCB, cast(A.ACQUIREDDATE as Date) AS NgayBoSung, A.LocationID, T.RECOMMENDID,
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
			JOIN FPT_RECOMMEND_ITEM T ON A.ITEMID = T.ITEMID
			join (select R.ItemID as ItemID, C.DisplayEntry as NXB
					from ITEM_PUBLISHER R, CAT_DIC_PUBLISHER C
					where R.PublisherID = C.ID) as R on A.ItemID = R.ItemID
		WHERE A.LocationID = @LocID AND A.AcquiredDate >= CONVERT (varchar(10), @StartDate, 21) 
		AND A.AcquiredDate <= CONVERT (varchar(10), @EndDate, 21) and F.FieldCode = 245 and T.RECOMMENDID = @reid
		ORDER BY NgayBoSung desc, U.DKCB desc
	END
END
	
END

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





GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_CATA_GET_CONTENTS_OF_ITEMS]    Script Date: 7/9/2019 3:16:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
--FPT_SP_CATA_GET_CONTENTS_OF_ITEMS'1090',0
--Doanhdq created
--use to display all property by  Record
--Fixed : 852 khong lay thong tin ma dang ky ca biet
CREATE        PROCEDURE [dbo].[FPT_SP_CATA_GET_CONTENTS_OF_ITEMS]
	@strItemIDs varchar(1000),
	@intIsAuthority INT
AS

IF @intIsAuthority = 0 
	BEGIN
		--Ldr
		SELECT '000' as IDSort,'Ldr' as FieldCode, '' as Ind, Leader as Content
		FROM ITEM I , CAT_DIC_MEDIUM M, CAT_DIC_ITEM_TYPE D 
		WHERE 
		I.MediumID=M.ID 
		AND I.TypeID = D.ID
		AND I.ID IN (@strItemIDs)
		
		--Code
		UNION
		SELECT '001' as IDSort,'001' as FieldCode, '' as Ind, I.Code as Content
		FROM ITEM I , CAT_DIC_MEDIUM M, CAT_DIC_ITEM_TYPE D 
		WHERE 
		I.MediumID=M.ID 
		AND I.TypeID = D.ID
		AND I.ID IN (@strItemIDs)
		
		--Field000s
		UNION 
		SELECT M.FieldCode as IDSort, M.FieldCode,REPLACE(F.Ind1,' ','#')  + REPLACE(F.Ind2,' ','#')  as Ind, F.Content as Content
		FROM Field000s F, MARC_BIB_FIELD M
		WHERE M.FieldCode=F.FieldCode AND F.ItemID IN (@strItemIDs)  
		
		--Field100s
		UNION 
		SELECT M.FieldCode as IDSort, M.FieldCode,REPLACE(F.Ind1,' ','#')  + REPLACE(F.Ind2,' ','#')  as Ind, F.Content as Content 
		FROM Field100s F, MARC_BIB_FIELD M 
		WHERE M.FieldCode=F.FieldCode AND F.ItemID IN (@strItemIDs)  
		
		--Field200s
		UNION 
		SELECT M.FieldCode as IDSort, M.FieldCode,REPLACE(F.Ind1,' ','#')  + REPLACE(F.Ind2,' ','#')  as Ind, F.Content as Content
		FROM Field200s F, MARC_BIB_FIELD M 
		WHERE M.FieldCode=F.FieldCode AND F.ItemID IN (@strItemIDs) 
		
		--Field300s
		UNION 
		SELECT M.FieldCode as IDSort, M.FieldCode,REPLACE(F.Ind1,' ','#')  + REPLACE(F.Ind2,' ','#')  as Ind, F.Content as Content 
		FROM Field300s F, MARC_BIB_FIELD M 
		WHERE M.FieldCode=F.FieldCode AND F.ItemID IN (@strItemIDs) 
		
		--Field400s
		UNION 
		SELECT M.FieldCode as IDSort, M.FieldCode,REPLACE(F.Ind1,' ','#')  + REPLACE(F.Ind2,' ','#')  as Ind, F.Content as Content
		FROM Field400s F, MARC_BIB_FIELD M 
		WHERE M.FieldCode=F.FieldCode AND F.ItemID IN (@strItemIDs) 
		
		--Field500s
		UNION 
		SELECT M.FieldCode as IDSort, M.FieldCode,REPLACE(F.Ind1,' ','#')  + REPLACE(F.Ind2,' ','#')  as Ind, F.Content as Content 
		FROM Field500s F, MARC_BIB_FIELD M 
		WHERE M.FieldCode=F.FieldCode AND F.ItemID IN (@strItemIDs) 
		
		--Field600s
		UNION 
		SELECT M.FieldCode as IDSort, M.FieldCode,REPLACE(F.Ind1,' ','#')  + REPLACE(F.Ind2,' ','#')  as Ind, F.Content as Content
		FROM Field600s F, MARC_BIB_FIELD M 
		WHERE M.FieldCode=F.FieldCode AND F.ItemID IN (@strItemIDs) 
		
		--Field700s
		UNION 
		SELECT M.FieldCode as IDSort, M.FieldCode,REPLACE(F.Ind1,' ','#')  + REPLACE(F.Ind2,' ','#')  as Ind, F.Content as Content 
		FROM Field700s F, MARC_BIB_FIELD M 
		WHERE M.FieldCode=F.FieldCode AND F.ItemID IN (@strItemIDs) 
		
		--Field800s
		UNION 
		SELECT M.FieldCode as IDSort, M.FieldCode,REPLACE(F.Ind1,' ','#')  + REPLACE(F.Ind2,' ','#')  as Ind, F.Content as Content
		FROM Field800s F, MARC_BIB_FIELD M 
		WHERE M.FieldCode=F.FieldCode AND F.ItemID IN (@strItemIDs) 
		
		--Field900s
		UNION 
		SELECT M.FieldCode as IDSort, M.FieldCode,REPLACE(F.Ind1,' ','#')  + REPLACE(F.Ind2,' ','#')  as Ind, F.Content as Content
		FROM Field900s F, MARC_BIB_FIELD M 
		WHERE M.FieldCode=F.FieldCode AND F.ItemID IN (@strItemIDs) 
		
		--NewRecord
		UNION
		SELECT '900' as IDSort,'900' as FieldCode, '' as Ind, CAST(I.NewRecord as varchar(5)) as Content
		FROM ITEM I , CAT_DIC_MEDIUM M, CAT_DIC_ITEM_TYPE D 
		WHERE 
		I.MediumID=M.ID 
		AND I.TypeID = D.ID
		AND I.ID IN (@strItemIDs)
		
		--CoverPicture
		UNION
		SELECT '907' as IDSort,'907' as FieldCode, '' as Ind, I.CoverPicture as Content
		FROM ITEM I , CAT_DIC_MEDIUM M, CAT_DIC_ITEM_TYPE D 
		WHERE 
		I.MediumID=M.ID 
		AND I.TypeID = D.ID
		AND I.ID IN (@strItemIDs)
		AND CoverPicture IS NOT NULL AND CoverPicture <> ''
		
		--Reviewer
		UNION
		SELECT '912' as IDSort,'912' as FieldCode, '' as Ind, I.Reviewer as Content
		FROM ITEM I , CAT_DIC_MEDIUM M, CAT_DIC_ITEM_TYPE D 
		WHERE 
		I.MediumID=M.ID 
		AND I.TypeID = D.ID
		AND I.ID IN (@strItemIDs)
		AND Reviewer  IS NOT NULL AND Reviewer <>''
		
		--Cataloguer
		UNION
		SELECT '911' as IDSort,'911' as FieldCode, '' as Ind,  I.Cataloguer as Content
		FROM ITEM I , CAT_DIC_MEDIUM M, CAT_DIC_ITEM_TYPE D 
		WHERE 
		I.MediumID=M.ID 
		AND I.TypeID = D.ID
		AND I.ID IN (@strItemIDs)
		AND Cataloguer  IS NOT NULL AND Cataloguer  <>''
		
		--M.Code
		UNION
		SELECT '925' as IDSort,'925' as FieldCode, '' as Ind, M.Code as Content
		FROM ITEM I , CAT_DIC_MEDIUM M, CAT_DIC_ITEM_TYPE D 
		WHERE 
		I.MediumID=M.ID 
		AND I.TypeID = D.ID
		AND I.ID IN (@strItemIDs)
		
		--AccessLevel
		UNION
		SELECT '926' as IDSort,'926' as FieldCode, '' as Ind, CAST(I.AccessLevel as varchar(1)) as Content
		FROM ITEM I , CAT_DIC_MEDIUM M, CAT_DIC_ITEM_TYPE D 
		WHERE 
		I.MediumID=M.ID 
		AND I.TypeID = D.ID
		AND I.ID IN (@strItemIDs)
		
		--D.TypeCode
		UNION
		SELECT '927' as IDSort,'927' as FieldCode, '' as Ind, D.TypeCode as Content
		FROM ITEM I , CAT_DIC_MEDIUM M, CAT_DIC_ITEM_TYPE D 
		WHERE 
		I.MediumID=M.ID 
		AND I.TypeID = D.ID
		AND I.ID IN (@strItemIDs)
			-- copynumber : 852$j
			--Doanhdq
	    --union
	    --SELECT distinct '852' as IDSort,'852' as FieldCode, '' as Ind,  '$a' + HLB.code + '$b' + hl.symbol as Content
     --   FROM HOLDING H, HOLDING_LOCATION HL, HOLDING_LIBRARY HLB WHERE H.ItemID  =@strItemIDs AND H.locationid=HL.ID AND HL.LIBID=HLB.ID

		--ORDER
		
		ORDER BY IDSort
	END
ELSE
	BEGIN
		SELECT '0' as IDSort,'Ldr' as FieldCode, '0' as Ind, Leader as Content
		FROM CAT_AUTHORITY where
		ID IN (@strItemIDs)
		
		UNION
		-- 001 : code
		SELECT '001' as IDSort,'001' as FieldCode, '0' as Ind, Code as Content
		FROM CAT_AUTHORITY where
		ID IN (@strItemIDs)
		
		UNION	
		
		SELECT MA.FieldCode as IDSort,MA.FieldCode, REPLACE(FA.Ind1,' ','#')  + REPLACE(FA.Ind2,' ','#')  as Ind, REPLACE(FA.Content,' ','&nbsp;') as Content
		FROM Field_Authority FA, MARC_Authority_field MA
		WHERE MA.FieldCode = FA.FieldCode
		And AuthorityID IN (@strItemIDs)
		
		UNION	
		-- cataloguer
		SELECT '911' as IDSort,'911' as FieldCode, '0' as Ind, Cataloguer as Content
		FROM CAT_AUTHORITY CA 	
		where CA.ID IN (@strItemIDs)
		
		UNION	
		-- reviewer
		SELECT '912' as IDSort,'912' as FieldCode, '0' as Ind, Reviewer as Content
		FROM CAT_AUTHORITY CA 
		where	
		CA.ID IN (@strItemIDs)
		--ORDER
		
		ORDER BY IDSort;
	END
	


go
-- thêm dữ liệu vào bảng để tạo form biên mục--
INSERT [dbo].[MARC_WORKSHEET] ([ID], [Name], [Creator], [CreatedDate], [LastModifiedDate], [Note]) VALUES (14, N'Mẫu biên mục Sách (2019)', N'Nguyễn Thị Thơi', CAST(N'2019-06-13T00:00:00.000' AS DateTime), CAST(N'2019-06-13T00:00:00.000' AS DateTime), NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'001', 1, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'020$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'022$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'040$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'041$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'044$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'082$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'090$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'090$b', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'100$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'110$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'245$a', 1, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'245$b', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'245$b', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'245$c', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'245$n', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'245$p', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'246$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'250$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'260$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'260$b', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'260$c', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'300$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'300$b', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'300$c', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'300$e', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'490$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'500$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'520$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'650$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'653$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'700$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'852$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'900', 1, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'911', 1, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'925', 1, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'926', 1, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (14, N'927', 1, NULL, 0, NULL)

------	
--DOANHDQ /15/08/2019
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'001', 1, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'020$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'022$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'040$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'041$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'044$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'082$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'090$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'090$b', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'100$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'110$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'245$a', 1, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'245$b', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'245$b', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'245$c', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'245$n', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'245$p', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'246$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'250$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'260$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'260$b', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'260$c', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'300$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'300$b', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'300$c', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'300$e', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'490$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'500$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'520$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'650$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'653$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'700$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'852$a', 0, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'900', 1, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'911', 1, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'925', 1, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'926', 1, NULL, 0, NULL)
INSERT [dbo].[MARC_BIB_WS_DETAIL] ([FormID], [FieldCode], [Mandatory], [DefaultValue], [IstextBox], [DefaultIndicators]) VALUES (11, N'927', 1, NULL, 0, NULL)
------	

GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_LANGUAGE_DETAILS_STATISTIC]    Script Date: 07/26/2019 20:23:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_LANGUAGE_DETAILS_STATISTIC]
	@strTypeSelect VARCHAR(20),
	@intLibraryID int
AS
BEGIN	
	IF @strTypeSelect='ITEM'
		BEGIN
			IF NOT @intLibraryID = 0
				SELECT sum(A.Total) as Total,A.ISOCode FROM (SELECT Count(Distinct A.ItemID) AS Total,ISNULL(C.ISOCode,'Không XĐ')AS ISOCode FROM HOLDING A,ITEM_LANGUAGE B,CAT_DIC_LANGUAGE C WHERE B.LanguageID=C.ID AND A.ItemID=B.ItemID AND A.LibID = @intLibraryID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.ISOCode) A GROUP BY A.ISOCode ORDER BY Total DESC
			ELSE 
				SELECT sum(A.Total) as Total,A.ISOCode FROM (SELECT Count(*) AS Total,ISNULL(B.ISOCode,'Không XĐ')AS ISOCode FROM ITEM_LANGUAGE A,CAT_DIC_LANGUAGE B  WHERE A.LanguageID=B.ID AND Right(A.FieldCode,2)='$a'  GROUP BY B.ISOCode) A GROUP BY A.ISOCode ORDER BY Total DESC
		END	
	IF @strTypeSelect='COPY'
		BEGIN
			IF NOT @intLibraryID = 0
				SELECT sum(A.Total) as Total,A.ISOCode FROM (SELECT Count(*) AS Total,ISNULL(C.ISOCode,'Không XĐ')AS ISOCode FROM HOLDING A,ITEM_LANGUAGE B,CAT_DIC_LANGUAGE C WHERE B.LanguageID=C.ID AND A.ItemID=B.ItemID AND A.LibID = @intLibraryID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.ISOCode) A GROUP BY A.ISOCode ORDER BY Total DESC
			ELSE 
				SELECT sum(A.Total) as Total,A.ISOCode FROM (SELECT Count(*) AS Total,ISNULL(C.ISOCode,'Không XĐ')AS ISOCode FROM HOLDING A,ITEM_LANGUAGE B,CAT_DIC_LANGUAGE C WHERE B.LanguageID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.ISOCode) A GROUP BY A.ISOCode ORDER BY Total DESC
		END
	
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_LANGUAGE_STATISTIC]    Script Date: 07/26/2019 20:24:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_LANGUAGE_STATISTIC]
	@intLibraryID int
AS
BEGIN
	BEGIN
		IF NOT @intLibraryID = 0
			SELECT A.*,B.* FROM(SELECT  Count(Distinct ItemID) AS TotalBook FROM HOLDING WHERE LibID = @intLibraryID) A,(SELECT  Count (*) AS TotalCopies FROM HOLDING WHERE LibID = @intLibraryID) B    
		ELSE 
			SELECT A.*,B.* FROM(SELECT  Count(*) AS TotalBook FROM ITEM) A,(SELECT  Count (*) AS TotalCopies FROM HOLDING) B    
	END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_AUTHOR]    Script Date: 07/26/2019 20:24:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO TÁC GIẢ
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_AUTHOR]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM HOLDING A,ITEM_AUTHOR B,CAT_DIC_AUTHOR C 
			WHERE B.AuthorID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ')AS AccessEntry 
				FROM ITEM_AUTHOR B,CAT_DIC_AUTHOR C 
			WHERE B.AuthorID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_BBK]    Script Date: 07/26/2019 20:24:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO BBK
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_BBK]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_BBK B,CAT_DIC_CLASS_BBK C 
			WHERE B.BBKID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_BBK B,CAT_DIC_CLASS_BBK C 
			WHERE B.BBKID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END


GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_COUNTRY]    Script Date: 07/26/2019 20:24:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO COUNTRY
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_COUNTRY]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_COUNTRY B,CAT_DIC_COUNTRY C 
			WHERE B.CountryID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_COUNTRY B,CAT_DIC_COUNTRY C 
			WHERE B.CountryID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END


GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_DDC]    Script Date: 07/26/2019 20:24:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO DDC
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_DDC]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_DDC B,CAT_DIC_CLASS_DDC C 
			WHERE B.DDCID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_DDC B,CAT_DIC_CLASS_DDC C 
			WHERE B.DDCID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_DIC40]    Script Date: 07/26/2019 20:24:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO Chỉ số ISBN
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_DIC40]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_DICTIONARY40 B,DICTIONARY40 C 
			WHERE B.DICTIONARY40ID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_DICTIONARY40 B,DICTIONARY40 C 
			WHERE B.DICTIONARY40ID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END


GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_DIC41]    Script Date: 07/26/2019 20:25:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO Giá tiền
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_DIC41]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_DICTIONARY41 B,DICTIONARY41 C 
			WHERE B.DICTIONARY41ID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_DICTIONARY41 B,DICTIONARY41 C 
			WHERE B.DICTIONARY41ID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END


GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_DIC42]    Script Date: 07/26/2019 20:25:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO Khổ cỡ
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_DIC42]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_DICTIONARY42 B,DICTIONARY42 C 
			WHERE B.DICTIONARY42ID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$c'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_DICTIONARY42 B,DICTIONARY42 C 
			WHERE B.DICTIONARY42ID=C.ID AND Right(B.Fieldcode,2)='$c'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_DIC43]    Script Date: 07/26/2019 20:25:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO Mã xếp giá
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_DIC43]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_DICTIONARY43 B,DICTIONARY43 C 
			WHERE B.DICTIONARY43ID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_DICTIONARY43 B,DICTIONARY43 C 
			WHERE B.DICTIONARY43ID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_ITEMTYPE_NEW]    Script Date: 07/26/2019 20:25:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO DẠNG TÀI LIỆU
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_ITEMTYPE_NEW]
@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 A.TOTAL AS Total, B.CODE AS AccessEntry, B.NAME FROM(SELECT COUNT(H.ITEMID) AS TOTAL, I.TYPEID AS ID
			FROM HOLDING H, ITEM I WHERE H.ITEMID = I.ID
			GROUP BY I.TYPEID) A, (SELECT DISTINCT(I.TYPEID) AS ID, C.TYPECODE AS CODE, ISNULL(C.TYPENAME,'Không XĐ') AS NAME FROM ITEM I, CAT_DIC_ITEM_TYPE C WHERE I.TYPEID = C.ID) B
			WHERE A.ID = B.ID
			ORDER BY A.TOTAL DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 A.TOTAL as Total, B.CODE AS AccessEntry, B.NAME FROM(SELECT COUNT(DISTINCT H.ITEMID) AS TOTAL, I.TYPEID AS ID
			FROM HOLDING H, ITEM I WHERE H.ITEMID = I.ID
			GROUP BY I.TYPEID) A, (SELECT DISTINCT(I.TYPEID) AS ID, C.TYPECODE AS CODE, ISNULL(C.TYPENAME,'Không XĐ') AS NAME 
			FROM ITEM I, CAT_DIC_ITEM_TYPE C WHERE I.TYPEID = C.ID) B
			WHERE A.ID = B.ID
			ORDER BY A.TOTAL DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_KEYWORD]    Script Date: 07/26/2019 20:25:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO TỪ KHOÁ
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_KEYWORD]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM HOLDING A,ITEM_KEYWORD B,CAT_DIC_KEYWORD C 
			WHERE B.KeyWordID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_KEYWORD B,CAT_DIC_KEYWORD C 
			WHERE B.KeyWordID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_LANGUAGE]    Script Date: 07/26/2019 20:25:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO LANGUAGE
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_LANGUAGE]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_LANGUAGE B,CAT_DIC_LANGUAGE C 
			WHERE B.LanguageID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_LANGUAGE B,CAT_DIC_LANGUAGE C 
			WHERE B.LanguageID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_LIBRARY_NEW]    Script Date: 07/26/2019 20:26:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO DẠNG TÀI LIỆU
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_LIBRARY_NEW]
	@intType int
AS
BEGIN
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 A.TOTAL AS Total, B.CODE AS AccessEntry, B.NAME FROM(SELECT COUNT(H.ITEMID) AS TOTAL, H.LIBID AS ID
			FROM HOLDING H, ITEM I WHERE H.ITEMID = I.ID
			GROUP BY H.LIBID) A, (SELECT DISTINCT(H.LIBID) AS ID, L.CODE AS CODE, ISNULL(L.ACCESSENTRY,'Không XĐ') AS NAME FROM HOLDING H, HOLDING_LIBRARY L WHERE H.LIBID = L.ID) B
			WHERE A.ID = B.ID
			ORDER BY A.TOTAL DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 A.TOTAL AS Total, B.CODE AS AccessEntry, B.NAME FROM(SELECT COUNT(DISTINCT H.ITEMID) AS TOTAL, H.LIBID AS ID
			FROM HOLDING H, ITEM I WHERE H.ITEMID = I.ID
			GROUP BY H.LIBID) A, (SELECT DISTINCT(H.LIBID) AS ID, L.CODE AS CODE, ISNULL(L.ACCESSENTRY,'Không XĐ') AS NAME FROM HOLDING H, HOLDING_LIBRARY L WHERE H.LIBID = L.ID) B
			WHERE A.ID = B.ID
			ORDER BY A.TOTAL DESC
		END
	
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_LOC]    Script Date: 07/26/2019 20:26:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO LOC
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_LOC]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_LOC B,CAT_DIC_CLASS_LOC C 
			WHERE B.LOCID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_LOC B,CAT_DIC_CLASS_LOC C 
			WHERE B.LOCID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END


GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_MEDIUM_NEW]    Script Date: 07/26/2019 20:26:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO VẬT MANG TIN
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_MEDIUM_NEW]
	@intType int
AS
BEGIN
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 A.TOTAL as Total, B.CODE, B.NAME as AccessEntry FROM(SELECT COUNT(I.MEDIUMID) AS TOTAL, I.MEDIUMID AS ID
			FROM HOLDING H, ITEM I WHERE H.ITEMID = I.ID
			GROUP BY I.MEDIUMID) A, (SELECT DISTINCT(I.MEDIUMID) AS ID, C.CODE AS CODE, ISNULL(C.DESCRIPTION,C.ACCESSENTRY) AS NAME FROM ITEM I, CAT_DIC_MEDIUM C WHERE I.MEDIUMID = C.ID) B
			WHERE A.ID = B.ID
			ORDER BY A.TOTAL DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 A.TOTAL as Total, B.CODE, B.NAME as AccessEntry FROM(SELECT COUNT(I.MEDIUMID) AS TOTAL, I.MEDIUMID AS ID
			FROM ITEM I
			GROUP BY I.MEDIUMID) A, (SELECT DISTINCT(I.MEDIUMID) AS ID, C.CODE AS CODE, ISNULL(C.DESCRIPTION,C.ACCESSENTRY) AS NAME FROM ITEM I, CAT_DIC_MEDIUM C WHERE I.MEDIUMID = C.ID) B
			WHERE A.ID = B.ID
			ORDER BY A.TOTAL DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_NLM]    Script Date: 07/26/2019 20:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO NLM
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_NLM]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_NLM B,CAT_DIC_CLASS_NLM C 
			WHERE B.NLMID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_NLM B,CAT_DIC_CLASS_NLM C 
			WHERE B.NLMID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_OAI_SET]    Script Date: 07/26/2019 20:26:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO OAI Set
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_OAI_SET]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_OAI_SET B,CAT_DIC_OAI_SET C 
			WHERE B.OaiID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_OAI_SET B,CAT_DIC_OAI_SET C 
			WHERE B.OaiID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_PUBLISHER]    Script Date: 07/26/2019 20:26:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO NHÀ XUẤT BẢN
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_PUBLISHER]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM HOLDING A,ITEM_PUBLISHER B,CAT_DIC_PUBLISHER C 
			WHERE B.PublisherID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$b'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_PUBLISHER B,CAT_DIC_PUBLISHER C 
			WHERE B.PublisherID=C.ID AND Right(B.Fieldcode,2)='$b'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_SERIALS]    Script Date: 07/26/2019 20:26:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO SERIALS
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_SERIALS]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_SERIES B,CAT_DIC_SERIES C 
			WHERE B.SeriesID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_SERIES B,CAT_DIC_SERIES C 
			WHERE B.SeriesID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_SH]    Script Date: 07/26/2019 20:27:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO TIÊU ĐỀ ĐỀ MỤC
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_SH]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM HOLDING A,ITEM_SH B,CAT_DIC_SH C 
				WHERE B.SHID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ')AS AccessEntry 
				FROM ITEM_SH B,CAT_DIC_SH C 
				WHERE B.SHID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END


GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_THESIS_SUBJECT]    Script Date: 07/26/2019 20:27:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO Chuyen_nganh_luan_an
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_THESIS_SUBJECT]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_THESIS_SUBJECT B,CAT_DIC_THESIS_SUBJECT C 
			WHERE B.SubjectID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_THESIS_SUBJECT B,CAT_DIC_THESIS_SUBJECT C 
			WHERE B.SubjectID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_UDC]    Script Date: 07/26/2019 20:27:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO UDC
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20_BY_UDC]
	@intType int
AS
BEGIN 
	IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_UDC B,CAT_DIC_CLASS_UDC C 
			WHERE B.UDCID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_UDC B,CAT_DIC_CLASS_UDC C 
			WHERE B.UDCID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
END



GO
/****** Object:  StoredProcedure [dbo].[FPT_GET_PATRON_LOCK_STATISTIC]    Script Date: 07/27/2019 14:34:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[FPT_GET_PATRON_LOCK_STATISTIC]
-- Purpose: Get patron lock statistic
-- Created AnNXT
-- Date 14/07/2019
-- ModifyDate:
	@strPatronCode  varchar(50),
	@strNote nvarchar(200),
	@strLockDateFrom varchar(30),
	@strLockDateTo varchar(30),
	@intCollegeID int
AS
	DECLARE @strSql nvarchar(2000)
	DECLARE @strJoinSQL nvarchar(1000)
	DECLARE @strLikeSql nvarchar(1000)
	
	SET @strSql = 'SELECT CPL.PatronCode, CPL.StartedDate, CPL.Note,  ISNULL(CP.FirstName,'''') + '' '' + ISNULL(CP.MiddleName,'''') + '' '' + ISNULL(CP.LastName,'''') as FullName, CPL.StartedDate + CPL.LockedDays as FinishDate, CPL.LockedDays '
	SET @strLikeSql = '1 =1 AND '
	SET @strJoinSQL = ''

	SET @strJoinSQL = @strJoinSQL + ' FROM CIR_PATRON_LOCK CPL, CIR_PATRON CP'
	SET @strLikeSql = @strLikeSql + ' UPPER(CPL.PatronCode)=UPPER(CP.Code) AND'
	
	IF NOT @strPatronCode = ''
		SET @strLikeSql = @strLikeSql + ' UPPER(CPL.PatronCode)=''' + UPPER(@strPatronCode) + ''' AND'
	
	IF NOT @intCollegeID = 0
		BEGIN
			SET @strSql = @strSql + ', CDC.COLLEGE'
			SET @strJoinSQL = @strJoinSQL + ', CIR_PATRON_UNIVERSITY CPU, CIR_DIC_COLLEGE CDC'
			SET @strLikeSql = @strLikeSql + ' CP.ID = CPU.PATRONID AND CPU.COLLEGEID = CDC.ID AND CPU.COLLEGEID = ' + CAST(@intCollegeID AS VARCHAR(20)) + ' AND'
		END
	
	IF NOT @strNote = ''	
		BEGIN
			SET @strLikeSQL = @strLikeSQL + ' CPL.Note LIKE N''%' + @strNote + '%'' AND'
		END
	
	IF NOT @strLockDateFrom = ''
		SET @strLikeSql = @strLikeSql + ' CPL.StartedDate >= ''' + @strLockDateFrom + ''' AND'
		
	IF NOT @strLockDateTo = ''
		SET @strLikeSql = @strLikeSql + ' CPL.StartedDate <= ''' + @strLockDateTo + ''' AND'
	
	SET @strSql = @strSql + @strJoinSQL + ' WHERE ' +@strLikeSQL
	SET @strSql = LEFT(@strSql,LEN(@strSql)-3) + ' ORDER BY CPL.StartedDate DESC'
EXEC (@stRSql)


GO

/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_HOLDING_REMOVED]    Script Date: 8/6/2019 07:55:08 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- Purpose: Select holidng_remove information
-- @strDateType: 1 - ngày nhận sách, 2 - ngày xóa sách, 3 - ngày gần nhất mà quyển sách được mượn
CREATE PROCEDURE [dbo].[FPT_SP_GET_HOLDING_REMOVED]
	@intLibID	NVARCHAR(100),
	@intLocID	NVARCHAR(100),
	@strShelf	NVARCHAR(10),
	@strCopyNumber	VARCHAR(33),
	@strCallNumber	NVARCHAR(32),
	@strLiquidCode NVARCHAR(100),
	@strVolume	NVARCHAR(32),
	@strTitle	NVARCHAR(1000),
	@strPrice	NVARCHAR(1000),
	@strDateFrom DAtetime,
	@strDateTo DAtetime, 
	@strDateType NVARCHAR(1000),
	@strReason NVARCHAR(100)
AS
	DECLARE @strSQL NVARCHAR(4000)
	DECLARE @strWhere NVARCHAR(4000)
	DECLARE @strTable	NVARCHAR(1000)



	SET @strSQL='SELECT HOLDING_REMOVED.*,LEFT(FIELD200S.Content,50) AS Content,
		HOLDING_REMOVED.REASON as REASON_ID,HOLDING_REMOVE_REASON.REASON as Reson_detail '

	SET @strTable=' FROM (HOLDING_REMOVED Join HOLDING_LOCATION hl on hl.id = HOLDING_REMOVED.LocationID) ,FIELD200S,HOLDING_REMOVE_REASON '

	SET @strWhere=' WHERE Field200s.FieldCode=''245'' AND FIELD200S.ItemID=HOLDING_REMOVED.ItemID 
		AND HOLDING_REMOVE_REASON.ID=HOLDING_REMOVED.Reason'

	IF @strTitle<>'' 
	BEGIN
		SET @strTable=@strTable + ', ITEM_TITLE'	
		SET @strWhere=@strWhere + ' AND HOLDING_REMOVED.ItemID=ITEM_TITLE.ItemID AND ITEM_TITLE.FieldCode=''245'''
	END

	IF @intLibID<>0 
		BEGIN
			SET @strWhere= @strWhere + ' AND HOLDING_LIBRARY.ID=HOLDING_REMOVED.LibID 
			AND HOLDING_REMOVED.LibID=' + RTrim(CAST(@intLibID AS CHAR))

			IF PATINDEX('%,HOLDING_LIBRARY%',@strTable)=0
				SET @strTable= @strTable + ',HOLDING_LIBRARY'
			SET @strSQL=@strSQL + ',Code AS LibName'
		END
	ELSE
		BEGIN
			SET @strSQL=@strSQL + ',Code AS LibName '
			SET @strTable = @strTable + ' , HOLDING_LIBRARY  '
			SET @strWhere = @strWhere + ' AND HOLDING_LIBRARY.ID = HOLDING_REMOVED.LibID '
		END
	IF @intLocID<>0 
		BEGIN
			SET @strWhere= @strWhere + ' AND HOLDING_LOCATION.ID=HOLDING_REMOVED.LocationID 
			AND HOLDING_REMOVED.LocationID=' + RTrim(CAST(@intLocID AS CHAR))
			IF PATINDEX('%, HOLDING_LOCATION%',@strTable)=0
				SET @strTable= @strTable + ',HOLDING_LOCATION '			
		END

	IF @strShelf<>''
		BEGIN
			IF @strShelf='noname'
				SET @strWhere= @strWhere + ' AND (Shelf IS NULL  OR RTrim(LTrim(Shelf)) ='''')'
			ELSE
				SET @strWhere= @strWhere + ' AND Shelf LIKE ''' + @strShelf + ''''
		END
	IF @strCopyNumber<>''
		SET @strWhere= @strWhere + ' AND CopyNumber LIKE ''' + @strCopyNumber + ''''
	IF @strCallNumber<>''
		SET @strWhere= @strWhere + ' AND CallNumber LIKE ''' + @strCallNumber + ''''
	IF @strVolume<>''
		SET @strWhere= @strWhere + ' AND Volume LIKE ''' + @strVolume + ''''
	IF @strTitle<>''
		SET @strWhere= @strWhere + ' AND CONTAINS(Title,''"' + @strTitle +  '"'')'
	IF @strPrice<>''
		SET @strWhere= @strWhere + ' And Price = ' + @strPrice + ' '
	IF @strLiquidCode <>''
		SET @strWhere = @strWhere + ' And LiquidCode = ''' + @strLiquidCode + ''''
	SET @strTable = @strTable + ' '

	SET @strSQL=@strSQL + ', hl.Symbol AS LocName'

	if @strReason<>'-1'
		SET @strWhere = @strWhere + ' and HOLDING_REMOVED.Reason = ' + @strReason + ' ' 

	if @strDateType=1
		begin
			if Convert(nvarchar,@strDateFrom,23) <> ''
				SET @strWhere = @strWhere + ' and HOLDING_REMOVED.AcquiredDate >=''' + Convert(nvarchar,@strDateFrom,23) +'''' 
			if Convert(nvarchar,@strDateTo,23) <> ''
				SET @strWhere = @strWhere + ' and HOLDING_REMOVED.AcquiredDate <=''' + Convert(nvarchar,DATEADD(DAY,1,@strDateTo),23) +''''
		end
	else if @strDateType=2
		begin 
			if Convert(nvarchar,@strDateFrom,23) <> ''
				SET @strWhere = @strWhere + ' and HOLDING_REMOVED.RemovedDate >=''' + Convert(nvarchar,@strDateFrom,23) +'''' 
			if Convert(nvarchar,@strDateTo,23) <> ''
				SET @strWhere = @strWhere + ' and HOLDING_REMOVED.RemovedDate <''' + Convert(nvarchar,DATEADD(DAY,1,@strDateTo),23) +''''
		end
	else if @strDateType = 3
		begin 
			if Convert(nvarchar,@strDateFrom,23) <> ''
				SET @strWhere = @strWhere + ' and HOLDING_REMOVED.DateLastUsed >=''' + Convert(nvarchar,@strDateFrom,23) +'''' 
			if Convert(nvarchar,@strDateTo,23) <> ''
				SET @strWhere = @strWhere + ' and HOLDING_REMOVED.DateLastUsed <''' + Convert(nvarchar,DATEADD(DAY,1,@strDateTo),23) +''''
		end

PRINT @strSQL + @strTable + @strWhere
	EXECUTE(@strSQL + @strTable + @strWhere)
GO


	
	
	GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_HOLDING_REMOVED_PAGING]    Script Date: 7/24/2019 02:52:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Purpose: Select holidng_remove information
-- In: some infor
-- Creator: Vantd
-- CreatedDate: 09/03/2005
-- LastModifiedDate: 02/12/2005 by Sondp
CREATE PROCEDURE [dbo].[FPT_SP_GET_HOLDING_REMOVED_PAGING]
	@intLibID	NVARCHAR(100),
	@intLocID	NVARCHAR(100),
	@strShelf	NVARCHAR(10),
	@strCopyNumber	VARCHAR(33),
	@strCallNumber	NVARCHAR(32),
	@strVolume	NVARCHAR(32),
	@strTitle	NVARCHAR(1000),
	@numberIndex NVARCHAR(500),
	@numberRecordPerPage NVARCHAR(500)
AS
	DECLARE @strSQL NVARCHAR(4000)
	DECLARE @strWhere NVARCHAR(4000)
	DECLARE @strTable	NVARCHAR(1000)
	DECLARE @strPaging NVARCHAR(1000)
	DECLARE @numberIndexs int
	DECLARE @numberRecordPerPages int

	SET @numberIndexs = CAST(@numberIndex as int)
	SET @numberRecordPerPages = CAST(@numberRecordPerPage as int)


	SET @strSQL='SELECT HOLDING_REMOVED.*,LEFT(FIELD200S.Content,50) AS Content,
		HOLDING_REMOVED.REASON as REASON_ID,HOLDING_REMOVE_REASON.REASON '

	SET @strTable=' FROM (HOLDING_REMOVED Join HOLDING_LOCATION hl on hl.id = HOLDING_REMOVED.LocationID) ,FIELD200S,HOLDING_REMOVE_REASON '

	SET @strWhere=' WHERE Field200s.FieldCode=''245'' AND FIELD200S.ItemID=HOLDING_REMOVED.ItemID 
		AND HOLDING_REMOVE_REASON.ID=HOLDING_REMOVED.Reason'

	IF @strTitle<>'' 
	BEGIN
		SET @strTable=@strTable + ', ITEM_TITLE'	
		SET @strWhere=@strWhere + ' AND HOLDING_REMOVED.ItemID=ITEM_TITLE.ItemID AND ITEM_TITLE.FieldCode=''245'''
	END

	IF @intLibID<>0 
		BEGIN
			SET @strWhere= @strWhere + ' AND HOLDING_LIBRARY.ID=HOLDING_REMOVED.LibID 
			AND HOLDING_REMOVED.LibID=' + RTrim(CAST(@intLibID AS CHAR))

			IF PATINDEX('%,HOLDING_LIBRARY%',@strTable)=0
				SET @strTable= @strTable + ',HOLDING_LIBRARY'
			SET @strSQL=@strSQL + ',Code AS LibName'
		END
	ELSE
		SET @strSQL=@strSQL + ','' '' AS LibName'

	IF @intLocID<>0 
		BEGIN
			SET @strWhere= @strWhere + ' AND HOLDING_LOCATION.ID=HOLDING_REMOVED.LocationID 
			AND HOLDING_REMOVED.LocationID=' + RTrim(CAST(@intLocID AS CHAR))
			IF PATINDEX('%, HOLDING_LOCATION%',@strTable)=0
				SET @strTable= @strTable + ',HOLDING_LOCATION '			

		END


	IF @strShelf<>''
		BEGIN
			IF @strShelf='noname'
				SET @strWhere= @strWhere + ' AND (Shelf IS NULL  OR RTrim(LTrim(Shelf)) ='''')'
			ELSE
				SET @strWhere= @strWhere + ' AND Shelf LIKE ''' + @strShelf + ''''
		END
	IF @strCopyNumber<>''
		SET @strWhere= @strWhere + ' AND CopyNumber LIKE ''' + @strCopyNumber + ''''
	IF @strCallNumber<>''
		SET @strWhere= @strWhere + ' AND CallNumber LIKE ''' + @strCallNumber + ''''
	IF @strVolume<>''
		SET @strWhere= @strWhere + ' AND Volume LIKE ''' + @strVolume + ''''
	IF @strTitle<>''
		SET @strWhere= @strWhere + ' AND CONTAINS(Title,''"' + @strTitle +  '"'')'
	SET @strTable = @strTable + ' '

	SET @strSQL=@strSQL + ', hl.Symbol AS LocName'

	SET @strPaging = ' ORDER BY HOLDING_REMOVED.ID ASC
						OFFSET ' + CAST(@numberRecordPerPages*(@numberIndexs-1) as char)
						+' ROWS FETCH NEXT '+ @numberRecordPerPage +' ROWS ONLY;'


PRINT @strSQL + @strTable + @strWhere + @strPaging
	EXECUTE(@strSQL + @strTable + @strWhere + @strPaging)


GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_ITEM]    Script Date: 07/28/2019 17:32:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<ducnv>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ DANH MỤC SÁCH NHẬP
-- =============================================
Create  PROCEDURE [dbo].[FPT_SP_GET_ITEM]

      @strFromDate VARCHAR(30),

      @strToDate  VARCHAR(30),

      @intLocationID    int,
      
      @intLibraryID int

AS   

      DECLARE @strSQL NVARCHAR(1000)
	  DECLARE @strLike NVARCHAR(1000)
	  DECLARE @strJoin NVARCHAR(1000)
      SET @strSQL=''
      SET @strJoin=''
	  SET @strLike = ''
      SET @strSQL=@strSQL + 'SELECT I.ID,I.Code, U.DKCB, F.Content 
      FROM ITEM I
      join FIELD200S F on I.ID=F.ITEMID
join (SELECT distinct ItemID ,
STUFF(( SELECT  '', '' + CopyNumber
FROM HOLDING D1
WHERE D1.ItemID = D2.ItemID'
SET @strJoin = @strJoin+ 'FOR XML PATH('''')), 1, 1, '''') AS DKCB FROM HOLDING D2 GROUP BY ItemID) as U on I.ID = U.ItemID
WHERE FIELDCODE=''245'' AND (I.TYPEID=1 OR I.TypeID=15)'

      If @strFromDate<>''

            SET @strJoin=@strJoin + ' AND I.CreatedDate>=CONVERT(VARCHAR, '''+@strFromDate+''', 21)'

      If @strToDate<>''

            SET @strJoin=@strJoin + ' AND I.CreatedDate<=CONVERT(VARCHAR, '''+@strToDate+''', 21)'

      If @intLocationID <>0
		BEGIN
            SET @strJoin=@strJoin + ' AND I.ID IN (SELECT ITEMID FROM HOLDING WHERE LocationID='+ convert(nvarchar,@intLocationID) +')'
            SET @strLike = @strLike + ' AND D1.LocationID=' +convert(nvarchar,@intLocationID)
        END    
       If @intLocationID =0
		BEGIN
            SET @strJoin=@strJoin + ' AND I.ID IN (SELECT ITEMID FROM HOLDING WHERE LibID='+ convert(nvarchar,@intLibraryID) +')'
			SET @strLike = @strLike + ' AND D1.LibID=' +convert(nvarchar,@intLibraryID)
		END
		SET @strSQL = @strSQL+ @strLike + @strJoin
    --print(@strSQL)

      EXEC(@strSQL)

GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_HOLDING_REMOVED_PAGING_v2]    Script Date: 7/28/2019 04:21:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Purpose: Select holidng_remove information
-- In: some infor
-- Creator: Vantd
-- CreatedDate: 09/03/2005
-- LastModifiedDate: 02/12/2005 by Sondp
CREATE PROCEDURE [dbo].[FPT_SP_GET_HOLDING_REMOVED_PAGING_v2]
	@intLibID	NVARCHAR(100),
	@intLocID	NVARCHAR(100),
	@strShelf	NVARCHAR(10),
	@strCopyNumber	VARCHAR(33),
	@strCallNumber	NVARCHAR(32),
	@strVolume	NVARCHAR(32),
	@strTitle	NVARCHAR(1000),
	@numberIndex NVARCHAR(500),
	@numberRecordPerPage NVARCHAR(500)
AS
	DECLARE @strSQL NVARCHAR(4000)
	DECLARE @strWhere NVARCHAR(4000)
	DECLARE @strTable	NVARCHAR(1000)
	DECLARE @strPaging NVARCHAR(1000)
	DECLARE @numberIndexs int
	DECLARE @numberRecordPerPages int
	DECLARE @strfinal NVARCHAR(4000)

	SET @numberIndexs = CAST(@numberIndex as int)
	SET @numberRecordPerPages = CAST(@numberRecordPerPage as int)


	SET @strSQL='SELECT ROW_NUMBER() OVER (ORDER BY hr.ID) AS Seq, hr.*,LEFT(FIELD200S.Content,50) AS Content,
		hr.REASON as REASON_ID '

	SET @strTable=' FROM (HOLDING_REMOVED hr Join HOLDING_LOCATION hl on hl.id = hr.LocationID) ,FIELD200S,HOLDING_REMOVE_REASON hrr '

	SET @strWhere=' WHERE Field200s.FieldCode=''245'' AND FIELD200S.ItemID=hr.ItemID 
		AND hrr.ID=hr.Reason'

	IF @strTitle<>'' 
	BEGIN
		SET @strTable=@strTable + ', ITEM_TITLE'	
		SET @strWhere=@strWhere + ' AND hr.ItemID=ITEM_TITLE.ItemID AND ITEM_TITLE.FieldCode=''245'''
	END

	IF @intLibID<>0 
		BEGIN
			SET @strWhere= @strWhere + ' AND HOLDING_LIBRARY.ID=hr.LibID 
			AND hr.LibID=' + RTrim(CAST(@intLibID AS CHAR))

			IF PATINDEX('%,HOLDING_LIBRARY%',@strTable)=0
				SET @strTable= @strTable + ',HOLDING_LIBRARY'
			SET @strSQL=@strSQL + ',Code AS LibName'
		END
	ELSE
		SET @strSQL=@strSQL + ','' '' AS LibName'

	IF @intLocID<>0 
		BEGIN
			SET @strWhere= @strWhere + ' AND HOLDING_LOCATION.ID=hr.LocationID 
			AND hr.LocationID=' + RTrim(CAST(@intLocID AS CHAR))
			IF PATINDEX('%, HOLDING_LOCATION%',@strTable)=0
				SET @strTable= @strTable + ',HOLDING_LOCATION '			

		END


	IF @strShelf<>''
		BEGIN
			IF @strShelf='noname'
				SET @strWhere= @strWhere + ' AND (Shelf IS NULL  OR RTrim(LTrim(Shelf)) ='''')'
			ELSE
				SET @strWhere= @strWhere + ' AND Shelf LIKE ''' + @strShelf + ''''
		END
	IF @strCopyNumber<>''
		SET @strWhere= @strWhere + ' AND CopyNumber LIKE ''' + @strCopyNumber + ''''
	IF @strCallNumber<>''
		SET @strWhere= @strWhere + ' AND CallNumber LIKE ''' + @strCallNumber + ''''
	IF @strVolume<>''
		SET @strWhere= @strWhere + ' AND Volume LIKE ''' + @strVolume + ''''
	IF @strTitle<>''
		SET @strWhere= @strWhere + ' AND CONTAINS(Title,''"' + @strTitle +  '"'')'

	SET @strTable = @strTable + ' '

	SET @strSQL=@strSQL + ', hl.Symbol AS LocName'

	SET @strfinal = 'select a.*, hrr.REASON as REASON_DETAIL from ('+ @strSQL + @strTable + @strWhere + ' ) 
					a join HOLDING_REMOVE_REASON hrr on a.REASON_ID = hrr.ID 
					where a.Seq between ' + CAST(@numberRecordPerPages*(@numberIndexs-1)+1 as char)
						+  ' and ' + CAST(@numberRecordPerPages*(@numberIndexs) as char)
PRINT @strfinal
	EXECUTE(@strfinal)




GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_HOLDING_REMOVED_TOTAL_AMOUNT]    Script Date: 7/24/2019 02:52:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Purpose: Select holidng_remove information
-- In: some infor
-- Creator: Vantd
-- CreatedDate: 09/03/2005
-- LastModifiedDate: 02/12/2005 by Sondp
CREATE PROCEDURE [dbo].[FPT_SP_GET_HOLDING_REMOVED_TOTAL_AMOUNT]
	@intLibID	NVARCHAR(100),
	@intLocID	NVARCHAR(100),
	@strShelf	NVARCHAR(10),
	@strCopyNumber	VARCHAR(33),
	@strCallNumber	NVARCHAR(32),
	@strVolume	NVARCHAR(32),
	@strTitle	NVARCHAR(1000)
AS
	DECLARE @strSQL NVARCHAR(4000)
	DECLARE @strWhere NVARCHAR(4000)
	DECLARE @strTable	NVARCHAR(1000)
	SET @strSQL='SELECT COUNT(HOLDING_REMOVED.ID) as Total '

	SET @strTable=' FROM (HOLDING_REMOVED Join HOLDING_LOCATION hl on hl.id = HOLDING_REMOVED.LocationID) ,FIELD200S,HOLDING_REMOVE_REASON '

	SET @strWhere=' WHERE Field200s.FieldCode=''245'' AND FIELD200S.ItemID=HOLDING_REMOVED.ItemID 
		AND HOLDING_REMOVE_REASON.ID=HOLDING_REMOVED.Reason'

	IF @strTitle<>'' 
	BEGIN
		SET @strTable=@strTable + ', ITEM_TITLE'	
		SET @strWhere=@strWhere + ' AND HOLDING_REMOVED.ItemID=ITEM_TITLE.ItemID AND ITEM_TITLE.FieldCode=''245'''
	END

	IF @intLibID<>0 
		BEGIN
			SET @strWhere= @strWhere + ' AND HOLDING_LIBRARY.ID=HOLDING_REMOVED.LibID 
			AND HOLDING_REMOVED.LibID=' + RTrim(CAST(@intLibID AS CHAR))

			IF PATINDEX('%,HOLDING_LIBRARY%',@strTable)=0
				SET @strTable= @strTable + ',HOLDING_LIBRARY'
			
		END

	IF @intLocID<>0 
		BEGIN
			SET @strWhere= @strWhere + ' AND HOLDING_LOCATION.ID=HOLDING_REMOVED.LocationID 
			AND HOLDING_REMOVED.LocationID=' + RTrim(CAST(@intLocID AS CHAR))
			IF PATINDEX('%, HOLDING_LOCATION%',@strTable)=0
				SET @strTable= @strTable + ',HOLDING_LOCATION '			

		END


	IF @strShelf<>''
		BEGIN
			IF @strShelf='noname'
				SET @strWhere= @strWhere + ' AND (Shelf IS NULL  OR RTrim(LTrim(Shelf)) ='''')'
			ELSE
				SET @strWhere= @strWhere + ' AND Shelf LIKE ''' + @strShelf + ''''
		END
	IF @strCopyNumber<>''
		SET @strWhere= @strWhere + ' AND CopyNumber LIKE ''' + @strCopyNumber + ''''
	IF @strCallNumber<>''
		SET @strWhere= @strWhere + ' AND CallNumber LIKE ''' + @strCallNumber + ''''
	IF @strVolume<>''
		SET @strWhere= @strWhere + ' AND Volume LIKE ''' + @strVolume + ''''
	IF @strTitle<>''
		SET @strWhere= @strWhere + ' AND CONTAINS(Title,''"' + @strTitle +  '"'')'
	SET @strTable = @strTable + ' '

PRINT @strSQL + @strTable + @strWhere
	EXECUTE(@strSQL + @strTable + @strWhere)





      GO
/****** Object:  StoredProcedure [dbo].[FPT_COUNT_COPYNUMBER_BY_ITEMID]    Script Date: 07/28/2019 10:38:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<ducnv>
-- Create date: <Create Date,,>
-- Description:	<ĐẾM SỐ LƯỢNG ĐANG KÝ CÁ BIỆT TRONG KHO,,>
-- =============================================
Create PROCEDURE [dbo].[FPT_COUNT_COPYNUMBER_BY_ITEMID] 
@itemID int,
 @intLocationID int,
  @intLibraryID int
	-- Add the parameters for the stored procedure here
	
AS
DECLARE @strSQL NVARCHAR(1000)
SET @strSQL=''

      SET @strSQL=@strSQL +'SELECT COUNT(COPYNUMBER) as SLuong FROM HOLDING WHERE ITEMID = ' +convert(nvarchar,@itemID)

	If @intLocationID <>0
		 SET @strSQL=@strSQL +' AND  LocationID = ' +convert(nvarchar,@intLocationID)
	If @intLocationID =0
		SET @strSQL=@strSQL +' AND LibID = ' + convert(nvarchar,@intLibraryID)
--print(@strSQL)

      EXEC(@strSQL)


GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_HOLDING_REMOVED_WITH_ID]    Script Date: 7/24/2019 02:53:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FPT_SP_GET_HOLDING_REMOVED_WITH_ID]
	@strID	NVARCHAR(100)	
AS
	DECLARE @strSQL NVARCHAR(4000)
	DECLARE @strWhere NVARCHAR(4000)
	DECLARE @strTable	NVARCHAR(1000)
	SET @strSQL='SELECT HOLDING_REMOVED.*,LEFT(FIELD200S.Content,50) AS Content,
		HOLDING_REMOVED.REASON as REASON_ID,HOLDING_REMOVE_REASON.REASON '
	SET @strTable=' FROM (HOLDING_REMOVED Join HOLDING_LOCATION hl on hl.id = HOLDING_REMOVED.LocationID) ,FIELD200S,HOLDING_REMOVE_REASON '
	SET @strWhere=' WHERE Field200s.FieldCode=''245'' AND FIELD200S.ItemID=HOLDING_REMOVED.ItemID 
		AND HOLDING_REMOVE_REASON.ID=HOLDING_REMOVED.Reason and HOLDING_REMOVED.ID = ' + @strID
	SET @strTable = @strTable + ' '
	SET @strSQL=@strSQL + ', hl.Symbol AS LocName'
PRINT @strSQL + @strTable + @strWhere
	EXECUTE(@strSQL + @strTable + @strWhere)
go	
	
	
	
	GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_HOLDING_REMOVED_ITEM_DEL]    Script Date: 7/26/2019 12:28:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[FPT_SP_HOLDING_REMOVED_ITEM_DEL]
-- Purpose: Del data in tables HOLDING_REMOVED_...
-- ---------   ------  -------------------------------------------
 @strId	varchar(150)
AS
BEGIN TRAN DELETE_TRAN
	DELETE FROM HOLDING_REMOVED WHERE ID = @strId
IF @@Error>0 
BEGIN
	ROLLBACK TRAN DELETE_TRAN
	RETURN
END
COMMIT TRAN





GO
/****** Object:  StoredProcedure [dbo].[FPT_COUNT_COPYNUMBER_ONLOAN]    Script Date: 07/28/2019 10:41:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<DUCNV>
-- Create date: <Create Date,,>
-- Description:	<SỐ LƯỢNG ĐANG MƯỢN,,>
-- =============================================
Create PROCEDURE [dbo].[FPT_COUNT_COPYNUMBER_ONLOAN] 
@itemID int,
 @intLocationID int,
  @intLibraryID int
	-- Add the parameters for the stored procedure here
	
AS
DECLARE @strSQL NVARCHAR(1000)
SET @strSQL=''

      SET @strSQL=@strSQL +'SELECT COUNT(COPYNUMBER) as SLuong FROM CIR_LOAN WHERE ITEMID = ' +convert(nvarchar,@itemID)

	If @intLocationID <>0
		 SET @strSQL=@strSQL + ' AND ITEMID IN (SELECT ITEMID FROM HOLDING WHERE LocationID='+ convert(nvarchar,@intLocationID) +')'
	If @intLocationID =0
		SET @strSQL=@strSQL + ' AND ITEMID IN (SELECT ITEMID FROM HOLDING WHERE LibID='+ convert(nvarchar,@intLibraryID) +')'
--print(@strSQL)

      EXEC(@strSQL)
	  
	 
GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_HOLDING_LIBLOCUSER_SEL]    Script Date: 7/26/2019 01:23:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
Create PROCEDURE [dbo].[FPT_SP_HOLDING_LIBLOCUSER_SEL](@intLibID int)
AS
	SELECT CODE + ':' + SYMBOL AS LOCNAME, 
		B.ID AS ID, REPLACE(CAST(A.ID AS CHAR(3)) + ':' + CAST(B.ID AS CHAR(3)), ' ', '') AS GroupID, 
		A.ID AS LibID, B.Symbol, A.Code
	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B 
	WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.LibID = @intLibID
	ORDER BY B.LibID, B.Symbol	 
go	  
	  
	  
	  
	  
GO
/****** Object:  StoredProcedure [dbo].[SP_CIR_OVERDUELIST_GETINFOR]    */
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[FPT_SP_CIR_OVERDUELIST_GETINFOR]      
--purpose: select overdue items                       
--creator:Nhatnh                      
--createdDate:31/7/2019                      
 @intUserID INT,                      
 @strPatronIDs VARCHAR(1000),                    
  @whereCondition NVARCHAR(1000)                     
AS                      
 DECLARE @strSQL NVARCHAR(4000)                      
 SET @strSQL = ''                  
 SET @strSQL = '(SELECT L.ID AS LOANID, HD.LibID, HD.LocationID AS LocID,HD.Price,HD.Currency , CDC.College, CDF.Faculty, CPU.Grade, CPU.Class, CPU.FacultyID, CPU.CollegeID, P.PatronGroupID, L.LocationID, L.CheckOutDate AS CheckOutDate, L.DueDate AS CheckInDate, F.Content AS MainTitle, L.CopyNumber, P.ID AS PatronID, IsNull(P.FirstName,'''') + ''' + ' ' + ''' + IsNull(P.MiddleName,'''') + ''' + ' ' + ''' + IsNull(P.LastName,'''') AS Name,P.Email,'                 
    --TINH SO NGAY QUA HAN, VA TRU DI NGAY THU 7 VA CHU NHAT                      
 +'OverdueDate=DATEDIFF(DAY,L.DueDate,GETDATE()), '                      
 +'T.OverdueFine*floor(DATEDIFF(DAY,L.DueDate,GETDATE())) AS Penati, P.Code As PatronCode, P.Code,I.code as ItemCode FROM  CIR_LOAN L INNER JOIN CIR_PATRON P ON L.PatronID= P.ID INNER JOIN ITEM I ON L.ItemID=I.ID LEFT JOIN Field200s F ON I.ID=F.ItemID AND F.FieldCode=245 LEFT JOIN CIR_LOAN_TYPE T ON L.LoanTypeID=T.ID LEFT JOIN CIR_PATRON_UNIVERSITY CPU ON CPU.PatronID=P.ID LEFT JOIN CIR_DIC_FACULTY CDF ON CDF.ID=CPU.FacultyID LEFT JOIN CIR_DIC_COLLEGE CDC ON CDC.ID=CPU.CollegeID LEFT JOIN HOLDING HD ON HD.CopyNumber = L.CopyNumber WHERE  L.DueDate<=GETDATE()'                     
                      
 IF @strPatronIDs=''                       
  SET @strSQL= @strSQL + ' AND P.ID IN (SELECT DISTINCT L.PatronID FROM CIR_LOAN L WHERE L.DueDate<GETDATE())) A, '                      
 ELSE                      
  SET @strSQL= @strSQL + ' AND P.ID IN (' + @strPatronIDs + ')) A, '                      
 -- Get Location, Library                       
 SET @strSQL= 'SELECT A.*, B.LibCode, B.LocCode FROM ' + @strSQL + '(SELECT H.Symbol AS LocCode, H.ID, L.Code AS LibCode FROM HOLDING_LOCATION H, HOLDING_LIBRARY L WHERE H.LibID=L.ID AND H.ID IN(SELECT LocationID FROM SYS_USER_CIR_LOCATION WHERE UserID=' 
 + CAST(@intUserID AS NVARCHAR(4)) + ')) B WHERE A.LocationID=B.ID ' + @whereCondition + ' ORDER BY PatronCode '       
 EXEC(@strSQL)	  
 
 
 go
 /****** Object:  StoredProcedure [dbo].[FPT_SP_GET_GENERAL_LOC_INFOR_DUCNV]    Script Date: 8/6/2019 07:56:19 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--SP_GET_GENERAL_LOC_INFOR 20,31,'noname',1

--@intMode
--	=1: Trong kho
--	=0: Chua kiem nhan
-- InUsed:
-- =1: dang muon
-- =0: khong muon
-- InCirculation:
-- =0: dang khoa
CREATE  PROCEDURE [dbo].[FPT_SP_GET_GENERAL_LOC_INFOR_DUCNV] 
	@intLibID	INT,
	@intLocID	INT,
	@strShelf	NVARCHAR(10),
	@intMode	INT
AS
	IF @intLibID<>0
		BEGIN
			IF @intLocID<>0
				BEGIN
					IF @strShelf<>''
						BEGIN
							IF @strShelf='noname'
								BEGIN
									with A as
									(SELECT TOP 1 'INVENTORY' AS Type, Name AS VALUE, OpenedDate ,ClosedDate FROM INVENTORY,HOLDING_INVENTORY WHERE INVENTORY.ID=HOLDING_INVENTORY.InventoryID AND  LocationID=@intLocID AND LibID=@intLibID  ORDER BY OpenedDate  DESC)
									SELECT 'LIB' AS Type,Code AS VALUE,GETDATE() AS OpenedDate,GETDATE() AS ClosedDate FROM HOLDING_LIBRARY WHERE ID=@intLibID
									UNION SELECT 'LOC' AS Type,Symbol AS VALUE,GETDATE() AS OpenedDate,GETDATE() AS ClosedDate FROM HOLDING_LOCATION WHERE ID=@intLocID AND LibID=@intLibID
									UNION SELECT 'SUMCOPY' AS Type, RTRIM(CAST(COUNT(*) AS CHAR)) AS VALUE,GETDATE() AS OpenedDate,GETDATE() AS ClosedDate FROM HOLDING WHERE LocationID=@intLocID AND LibID=@intLibID  AND Acquired = @intMode
									UNION SELECT 'SUMITEM' AS Type, RTRIM(CAST(COUNT(DISTINCT ItemID)AS CHAR)) AS VALUE,GETDATE() AS OpenedDate,GETDATE() AS ClosedDate FROM HOLDING WHERE LocationID=@intLocID AND LibID=@intLibID  AND Acquired = @intMode
									UNION SELECT 'CountLocked' AS Type, RTRIM(CAST(COUNT(COPYNUMBER) AS CHAR)) AS VALUE, GETDATE() AS OpenedDate,GETDATE() AS ClosedDate FROM HOLDING WHERE LocationID=@intLocID AND LibID=@intLibID AND INCIRCULATION = 0 AND Acquired = @intMode
									UNION SELECT 'CountCir' AS Type, RTRIM(CAST(COUNT(COPYNUMBER) AS CHAR)) AS VALUE, GETDATE() AS OpenedDate,GETDATE() AS ClosedDate FROM HOLDING WHERE LocationID=@intLocID AND LibID=@intLibID AND INUSED = 1
									UNION SELECT * from A
								END
							ELSE
								BEGIN
								with A as
								(SELECT TOP 1 'INVENTORY' AS Type, Name AS VALUE, OpenedDate ,ClosedDate FROM INVENTORY,HOLDING_INVENTORY WHERE INVENTORY.ID=HOLDING_INVENTORY.InventoryID AND  LocationID=@intLocID AND LibID=@intLibID AND Shelf=@strShelf ORDER BY OpenedDate DESC)
									SELECT 'LIB' AS Type,Code AS VALUE,GETDATE() AS OpenedDate,GETDATE() AS ClosedDate FROM HOLDING_LIBRARY WHERE ID=@intLibID
									UNION SELECT 'LOC' AS Type,Symbol AS VALUE,GETDATE() AS OpenedDate,GETDATE() AS ClosedDate FROM HOLDING_LOCATION WHERE ID=@intLocID AND LibID=@intLibID
									UNION SELECT 'SUMCOPY' AS Type, RTRIM(CAST(COUNT(*) AS CHAR)) AS VALUE,GETDATE() AS OpenedDate,GETDATE() AS ClosedDate FROM HOLDING WHERE LocationID=@intLocID AND LibID=@intLibID AND Shelf=@strShelf AND Acquired = @intMode
									UNION SELECT 'SUMITEM' AS Type, RTRIM(CAST(COUNT(DISTINCT ItemID)AS CHAR)) AS VALUE,GETDATE() AS OpenedDate,GETDATE() AS ClosedDate FROM HOLDING WHERE LocationID=@intLocID AND LibID=@intLibID AND Shelf=@strShelf AND Acquired = @intMode
									UNION SELECT 'CountLocked' AS Type, RTRIM(CAST(COUNT(COPYNUMBER) AS CHAR)) AS VALUE, GETDATE() AS OpenedDate,GETDATE() AS ClosedDate FROM HOLDING WHERE LocationID=@intLocID AND LibID=@intLibID AND INCIRCULATION = 0 AND Acquired = @intMode
									UNION SELECT 'CountCir' AS Type, RTRIM(CAST(COUNT(COPYNUMBER) AS CHAR)) AS VALUE, GETDATE() AS OpenedDate,GETDATE() AS ClosedDate FROM HOLDING WHERE LocationID=@intLocID AND LibID=@intLibID AND INUSED = 1 AND Acquired = @intMode
									UNION select * from A
									END
						END
					ELSE
						BEGIN
						with A as(SELECT TOP 1 'INVENTORY' AS Type, Name AS VALUE, OpenedDate ,ClosedDate FROM INVENTORY,HOLDING_INVENTORY WHERE INVENTORY.ID=HOLDING_INVENTORY.InventoryID AND  LocationID=@intLocID AND LibID=@intLibID ORDER BY OpenedDate  DESC)
							SELECT 'LIB' AS Type,Code AS VALUE,GETDATE() AS OpenedDate,GETDATE() AS ClosedDate  FROM HOLDING_LIBRARY WHERE ID=@intLibID
							UNION SELECT 'LOC' AS Type,Symbol AS VALUE,GETDATE() AS OpenedDate,GETDATE() AS ClosedDate  FROM HOLDING_LOCATION WHERE ID=@intLocID AND LibID=@intLibID
							UNION SELECT 'SUMCOPY' AS Type, RTRIM(CAST(COUNT(*) AS CHAR)) AS VALUE,GETDATE() AS OpenedDate,GETDATE() AS ClosedDate  FROM HOLDING WHERE LocationID=@intLocID AND LibID=@intLibID AND InCirculation = @intMode AND Acquired = @intMode
							UNION SELECT 'SUMITEM' AS Type, RTRIM(CAST(COUNT(DISTINCT ItemID)AS CHAR)) AS VALUE,GETDATE() AS OpenedDate,GETDATE() AS ClosedDate  FROM HOLDING WHERE LocationID=@intLocID AND LibID=@intLibID AND Acquired = @intMode
							UNION SELECT 'CountLocked' AS Type,RTRIM(CAST(COUNT(COPYNUMBER) AS CHAR)) AS VALUE, GETDATE() AS OpenedDate,GETDATE() AS ClosedDate FROM HOLDING WHERE LocationID=@intLocID AND LibID=@intLibID AND INCIRCULATION = 0 AND Acquired = @intMode
							UNION SELECT 'CountCir' AS Type, RTRIM(CAST(COUNT(COPYNUMBER) AS CHAR)) AS VALUE, GETDATE() AS OpenedDate,GETDATE() AS ClosedDate FROM HOLDING WHERE LocationID=@intLocID AND LibID=@intLibID AND INUSED = 1 AND Acquired = @intMode	
							UNION select * from A
						END								
				END
			ELSE
				BEGIN
				with a as(SELECT TOP 1 'INVENTORY' AS Type, Name AS VALUE, OpenedDate ,ClosedDate FROM INVENTORY,HOLDING_INVENTORY WHERE INVENTORY.ID=HOLDING_INVENTORY.InventoryID AND LibID=@intLibID ORDER BY OpenedDate  DESC)
					SELECT 'LIB' AS Type,Code AS VALUE,GETDATE() AS OpenedDate,GETDATE() AS ClosedDate  FROM HOLDING_LIBRARY WHERE ID=@intLibID
					UNION SELECT 'SUMCOPY' AS Type, RTRIM(CAST(COUNT(*) AS CHAR)) AS VALUE,GETDATE() AS OpenedDate,GETDATE() AS ClosedDate  FROM HOLDING WHERE LibID=@intLibID AND Acquired = @intMode
					UNION SELECT 'SUMITEM' AS Type, RTRIM(CAST(COUNT(DISTINCT ItemID)AS CHAR)) AS VALUE,GETDATE() AS OpenedDate,GETDATE() AS ClosedDate  FROM HOLDING WHERE LibID=@intLibID AND Acquired = @intMode
					UNION SELECT 'CountLocked' AS Type, RTRIM(CAST(COUNT(COPYNUMBER) AS CHAR)) AS VALUE, GETDATE() AS OpenedDate,GETDATE() AS ClosedDate FROM HOLDING WHERE LibID=@intLibID AND INCIRCULATION = 0 AND Acquired = @intMode
					UNION SELECT 'CountCir' AS Type, RTRIM(CAST(COUNT(COPYNUMBER) AS CHAR)) AS VALUE, GETDATE() AS OpenedDate,GETDATE() AS ClosedDate FROM HOLDING WHERE LibID=@intLibID AND INUSED = 1	AND Acquired = @intMode		
					UNION select * from A
				END
		END

set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON

GO



go
/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_HOLDING_IDs_v1]    Script Date: 8/6/2019 07:56:01 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- intMode = 0: trong kho
-- intMode = 1: dang cho muon
-- intMode = 2: dang khoa
-- intMode = 3: chua kiem nhan
CREATE PROC [dbo].[FPT_SP_GET_HOLDING_IDs_v1]
	@intLibID	NVARCHAR(500),
	@intLocID	NVARCHAR(500),
	@strShelf	NVARCHAR(10),
	@intMode	NVARCHAR(500),
	@intCountOnly 	NVARCHAR(500),
	@numberIndex NVARCHAR(500),
	@numberRecordPerPage NVARCHAR(500)
AS
	DECLARE @strSQL VARCHAR(4000)
	DECLARE @strWhere NVARCHAR(4000)	
	DECLARE @strTable	VARCHAR(1000)	
	DECLARE @strfinal NVARCHAR(4000)
	DECLARE @numberIndexs int
	DECLARE @numberRecordPerPages int
	
	IF @intCountOnly=1 
	BEGIN
		SET @strSQL='SELECT Count(*) AS Total'
		SET @strTable=' FROM HOLDING,FIELD200S'
		SET @strWhere=' WHERE FIELD200S.FieldCode=''245'' AND FIELD200S.ItemID=HOLDING.ItemID'
		IF @intLibID>0 
			SET @strWhere=@strWhere + ' AND Holding.LibID=' + @intLibID 
		IF @intLocID>0 
			SET @strWhere=@strWhere + ' AND Holding.LocationID=' + @intLocID				
		
	END
	ELSE 
		BEGIN
			SET @strSQL='SELECT DISTINCT Acquired,ROW_NUMBER() OVER (ORDER BY HOLDING.CopyNumber) AS Seq,
			HOLDING.ID,HOLDING.LibID,HOLDING.LocationID,
			Content,ISNULL(Volume,'''') AS Volume,AcquiredDate,
			CopyNumber,ISNULL(CallNumber,'''') AS CallNumber,
			ISNULL(Shelf,'''') AS Shelf,InUsed,
			InCirculation,ISNULL(Note,'''') AS Note,DateLastUsed,Price,UseCount'
			SET @strTable=' FROM HOLDING,FIELD200S'
			SET @strWhere=' WHERE FIELD200S.FieldCode=''245'' AND FIELD200S.ItemID=HOLDING.ItemID'

			SET @strTable= @strTable + ',HOLDING_LOCATION '	
			SET @strTable= @strTable + ',HOLDING_LIBRARY '
			SET @strSQL=@strSQL + ', Code AS LibName '
			SET @strSQL=@strSQL + ',Symbol AS LocName '

			if @intLocID <>'' -- co locid, search theo ca libid va locid
				begin
					BEGIN
						SET @strWhere= @strWhere + ' AND HOLDING_LIBRARY.ID=HOLDING.LibID 
						AND HOLDING.LibID=' + @intLibID 
						SET @strWhere= @strWhere + ' AND HOLDING_LOCATION.ID=HOLDING.LocationID 
						AND HOLDING.LocationID=' + @intLocID
					END
				end
			else		-- khong co locid, chi search theo libid
				begin        
						SET @strWhere= @strWhere + ' AND HOLDING_LIBRARY.ID=HOLDING.LibID 
						AND HOLDING.LibID=' + @intLibID 
						SET @strWhere= @strWhere + ' AND HOLDING_LOCATION.ID=HOLDING.LocationID '
				end		
		END

	IF @strShelf='noname' SET @strWhere=@strWhere + ' AND(Holding.Shelf='''' OR Holding.Shelf IS NULL)'
	ELSE IF @strShelf<>'' SET @strWhere=@strWhere + ' AND Holding.Shelf LIKE ''' + @strShelf + ''''
	IF @intMode=0
		SET @strWhere= @strWhere + ' AND Acquired=1' --Trong kho
	IF @intMode=1
		SET @strWhere= @strWhere + ' AND InUsed=1' --dang cho muon
	IF @intMode=2
		SET @strWhere= @strWhere + ' AND InCirculation=0' -- Dang khoa
	IF @intMode=3		
		SET @strWhere= @strWhere + ' AND Acquired=0' -- chua kiem nhan	
	-- debug
	IF @numberIndex <> '' AND @numberRecordPerPage <> ''
	BEGIN
		SET @numberIndexs = CAST(@numberIndex as int)
		SET @numberRecordPerPages = CAST(@numberRecordPerPage as int)
		SET @strfinal = 'select a.* from ('+ @strSQL + @strTable + @strWhere + ' ) a 
				where a.Seq between ' + CAST(@numberRecordPerPages*(@numberIndexs-1)+1 as char)
					+  ' and ' + CAST(@numberRecordPerPages*(@numberIndexs) as char)
	END
	ELSE 
		SET @strfinal = @strSQL + @strTable + @strWhere
	PRINT @strfinal
	EXECUTE(@strfinal)	

GO


GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_HOLDING_IDs_v1_searching]    Script Date: 8/6/2019 07:56:10 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- intMode = 0: trong kho
-- intMode = 1: dang cho muon
-- intMode = 2: dang khoa
-- intMode = 3: chua kiem nhan
CREATE PROC [dbo].[FPT_SP_GET_HOLDING_IDs_v1_searching]
	@intLibID	NVARCHAR(500),
	@intLocID	NVARCHAR(500),
	@strShelf	NVARCHAR(10),
	@strCopyNumber	VARCHAR(33),
	@strCallNumber	NVARCHAR(32),
	@strVolume	NVARCHAR(32),
	@strTitle	NVARCHAR(1000),
	@intMode	NVARCHAR(500),
	@intCountOnly 	NVARCHAR(500),
	@numberIndex NVARCHAR(500),
	@numberRecordPerPage NVARCHAR(500)
AS
	DECLARE @strSQL VARCHAR(4000)
	DECLARE @strWhere NVARCHAR(4000)	
	DECLARE @strTable	VARCHAR(1000)	
	DECLARE @strfinal NVARCHAR(4000)
	DECLARE @numberIndexs int
	DECLARE @numberRecordPerPages int
	
	IF @intCountOnly=1 
	BEGIN
		SET @strSQL='SELECT Count(*) AS Total'
		SET @strTable=' FROM HOLDING,FIELD200S'
		SET @strWhere=' WHERE FIELD200S.FieldCode=''245'' AND FIELD200S.ItemID=HOLDING.ItemID'
		IF @intLibID>0 
			SET @strWhere=@strWhere + ' AND Holding.LibID=' + @intLibID 
		IF @intLocID>0 
			SET @strWhere=@strWhere + ' AND Holding.LocationID=' + @intLocID				
		
	END
	ELSE 
		BEGIN
			SET @strSQL='SELECT DISTINCT Acquired,ROW_NUMBER() OVER (ORDER BY HOLDING.CopyNumber) AS Seq,
			HOLDING.ID,HOLDING.LibID,HOLDING.LocationID,
			Content,ISNULL(Volume,'''') AS Volume,AcquiredDate,
			CopyNumber,ISNULL(CallNumber,'''') AS CallNumber,
			ISNULL(Shelf,'''') AS Shelf,InUsed,
			InCirculation,ISNULL(Note,'''') AS Note,DateLastUsed,Price,UseCount'
			SET @strTable=' FROM HOLDING,FIELD200S'
			SET @strWhere=' WHERE FIELD200S.FieldCode=''245'' AND FIELD200S.ItemID=HOLDING.ItemID'

			SET @strTable= @strTable + ',HOLDING_LOCATION '	
			SET @strTable= @strTable + ',HOLDING_LIBRARY '
			SET @strSQL=@strSQL + ', Code AS LibName '
			SET @strSQL=@strSQL + ',Symbol AS LocName '

			if @intLocID <>'' -- co locid, search theo ca libid va locid
				begin
					BEGIN
						SET @strWhere= @strWhere + ' AND HOLDING_LIBRARY.ID=HOLDING.LibID 
						AND HOLDING.LibID=' + @intLibID 
						SET @strWhere= @strWhere + ' HOLDING.LocationID=' + @intLocID
					END
				end
			else if @intLibID <> ''		-- khong co locid, chi search theo libid
				begin        
						SET @strWhere= @strWhere + ' AND HOLDING_LIBRARY.ID=HOLDING.LibID 
						AND HOLDING.LibID=' + @intLibID 
				end	
			else
			SET @strWhere= @strWhere + ' AND HOLDING_LOCATION.ID=HOLDING.LocationID AND HOLDING_LIBRARY.ID=HOLDING.LibID '
					
		END

	IF @strShelf='noname' SET @strWhere=@strWhere + ' AND(Holding.Shelf='''' OR Holding.Shelf IS NULL)'
	ELSE IF @strShelf<>'' SET @strWhere=@strWhere + ' AND Holding.Shelf LIKE ''' + @strShelf + ''''
	IF @intMode=0
		SET @strWhere= @strWhere + ' AND Acquired=1' --Trong kho
	IF @intMode=1
		SET @strWhere= @strWhere + ' AND InUsed=1' --dang cho muon
	IF @intMode=2
		SET @strWhere= @strWhere + ' AND InCirculation=0' -- Dang khoa
	IF @intMode=3		
		SET @strWhere= @strWhere + ' AND Acquired=0' -- chua kiem nhan	
	-- debug
	IF @strShelf<>''
		BEGIN
			IF @strShelf='noname'
				SET @strWhere= @strWhere + ' AND (Shelf IS NULL  OR RTrim(LTrim(Shelf)) ='''')'
			ELSE
				SET @strWhere= @strWhere + ' AND Shelf LIKE ''' + @strShelf + ''''
		END
	IF @strCopyNumber<>''
		SET @strWhere= @strWhere + ' AND CopyNumber LIKE ''' + @strCopyNumber + ''''
	IF @strCallNumber<>''
		SET @strWhere= @strWhere + ' AND CallNumber LIKE ''' + @strCallNumber + ''''
	IF @strVolume<>''
		SET @strWhere= @strWhere + ' AND Volume LIKE ''' + @strVolume + ''''
	IF @strTitle<>'' 
	BEGIN
		SET @strTable=@strTable + ', ITEM_TITLE'	
		SET @strWhere=@strWhere + ' AND HOLDING.ItemID=ITEM_TITLE.ItemID AND ITEM_TITLE.FieldCode=''245'''
		SET @strWhere= @strWhere + ' AND CONTAINS(Title,''"' + @strTitle +  '"'') '
	END
	IF @numberIndex <> '' AND @numberRecordPerPage <> ''
	BEGIN
		SET @numberIndexs = CAST(@numberIndex as int)
		SET @numberRecordPerPages = CAST(@numberRecordPerPage as int)
		SET @strfinal = 'select a.* from ('+ @strSQL + @strTable + @strWhere + ' ) a 
				where a.Seq between ' + CAST(@numberRecordPerPages*(@numberIndexs-1)+1 as char)
					+  ' and ' + CAST(@numberRecordPerPages*(@numberIndexs) as char)
	END
	ELSE 
		SET @strfinal = @strSQL + @strTable + @strWhere
	PRINT @strfinal
	EXECUTE(@strfinal)	

GO




GO

/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_HOLDING_IDs_v1_searching_with_id]    Script Date: 8/6/2019 07:55:23 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- intMode = 0: trong kho
-- intMode = 1: dang cho muon
-- intMode = 2: dang khoa
-- intMode = 3: chua kiem nhan
CREATE PROC [dbo].[FPT_SP_GET_HOLDING_IDs_v1_searching_with_id]
	@strItemID	NVARCHAR(500),
	@intMode	NVARCHAR(500),
	@intCountOnly 	NVARCHAR(500),
	@numberIndex NVARCHAR(500),
	@numberRecordPerPage NVARCHAR(500)
AS
	DECLARE @strSQL VARCHAR(4000)
	DECLARE @strWhere NVARCHAR(4000)	
	DECLARE @strTable	VARCHAR(1000)	
	DECLARE @strfinal NVARCHAR(4000)
	DECLARE @numberIndexs int
	DECLARE @numberRecordPerPages int
	
	IF @intCountOnly=1 
	BEGIN
		SET @strSQL='SELECT Count(*) AS Total'
		SET @strTable=' FROM HOLDING,FIELD200S'
		SET @strWhere=' WHERE FIELD200S.FieldCode=''245'' AND FIELD200S.ItemID=HOLDING.ItemID'
		
	END
	ELSE 
		BEGIN
			SET @strSQL='SELECT DISTINCT Acquired,ROW_NUMBER() OVER (ORDER BY HOLDING.CopyNumber) AS Seq,
			HOLDING.ID,HOLDING.LibID,HOLDING.LocationID,
			Content,ISNULL(Volume,'''') AS Volume,AcquiredDate,
			CopyNumber,ISNULL(CallNumber,'''') AS CallNumber,
			ISNULL(Shelf,'''') AS Shelf,InUsed,
			InCirculation,ISNULL(Note,'''') AS Note,DateLastUsed,Price,UseCount,HOLDING.ItemID, HOLDING.LoanTypeID,
			HOLDING.POID, HOLDING.AcquiredSourceID
			'
			SET @strTable=' FROM HOLDING,FIELD200S'
			SET @strWhere=' WHERE FIELD200S.FieldCode=''245'' AND FIELD200S.ItemID=HOLDING.ItemID'

			SET @strTable= @strTable + ',HOLDING_LOCATION '	
			SET @strTable= @strTable + ',HOLDING_LIBRARY '
			SET @strSQL=@strSQL + ', Code AS LibName '
			SET @strSQL=@strSQL + ',Symbol AS LocName '
			SET @strWhere= @strWhere + ' AND HOLDING_LIBRARY.ID=HOLDING.LibID '
			SET @strWhere= @strWhere + ' AND HOLDING_LOCATION.ID=HOLDING.LocationID '
			SET @strWhere= @strWhere + ' AND HOLDING.ID=  ' + @strItemID
		END


	IF @intMode=0
		SET @strWhere= @strWhere + ' AND Acquired=1' --Trong kho
	IF @intMode=1
		SET @strWhere= @strWhere + ' AND InUsed=1' --dang cho muon
	IF @intMode=2
		SET @strWhere= @strWhere + ' AND InCirculation=0' -- Dang khoa
	IF @intMode=3		
		SET @strWhere= @strWhere + ' AND Acquired=0' -- chua kiem nhan	
	-- debug
	IF @numberIndex <> '' AND @numberRecordPerPage <> ''
	BEGIN
		SET @numberIndexs = CAST(@numberIndex as int)
		SET @numberRecordPerPages = CAST(@numberRecordPerPage as int)
		SET @strfinal = 'select a.* from ('+ @strSQL + @strTable + @strWhere + ' ) a 
				where a.Seq between ' + CAST(@numberRecordPerPages*(@numberIndexs-1)+1 as char)
					+  ' and ' + CAST(@numberRecordPerPages*(@numberIndexs) as char)
	END
	ELSE 
		SET @strfinal = @strSQL + @strTable + @strWhere
	PRINT @strfinal
	EXECUTE(@strfinal)	

GO



GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_HOLDING_REMOVED_GET_COPYNUMBER_TO_INS]    Script Date: 8/6/2019 07:54:39 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[FPT_SP_GET_HOLDING_REMOVED_GET_COPYNUMBER_TO_INS]
	@strLibID	NVARCHAR(100),
	@strLocID	NVARCHAR(100)
AS
	DECLARE @strSQL NVARCHAR(4000)
	DECLARE @strWhere NVARCHAR(4000)
	DECLARE @strTable	NVARCHAR(1000)

	SET @strSQL = ' SELECT top 1 h.CopyNumber, hloc.Symbol '

	SET @strTable = ' FROM HOLDING h, HOLDING_LOCATION hloc, HOLDING_LIBRARY hlib '

	SET @strWhere = ' where h.LibID = hlib.ID and hloc.LibID = hlib.ID 
	and h.LocationID = hloc.ID and hloc.ID =  ' + @strLocID 
	+ ' and hlib.ID = ' + @strLibID + ' and h.Acquired=1 '
	PRINT @strSQL + @strTable + @strWhere + ' order by h.CopyNumber DESC'
	EXECUTE(@strSQL + @strTable + @strWhere + ' order by h.CopyNumber DESC ')
GO




GO

/****** Object:  StoredProcedure [dbo].[FPT_SP_HOLDING_DEL]    Script Date: 8/6/2019 07:56:57 AM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO



CREATE PROCEDURE [dbo].[FPT_SP_HOLDING_DEL]
	@strID 	NVARCHAR(1000)
AS
	DECLARE @strSql	NVARCHAR(4000)
		
	SET @strSql='DELETE FROM Holding WHERE ID = ' + @strID
print(@strSql)

EXECUTE(@strSql)
GO






GO

/****** Object:  StoredProcedure [dbo].[FPT_SP_HOLDING_REMOVED_INS]    Script Date: 8/6/2019 07:56:39 AM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO


-- Creator Kiemdv
-- Last Update 17/2/04 by Vantd
CREATE PROCEDURE [dbo].[FPT_SP_HOLDING_REMOVED_INS]  
	@intItemID 		INT, 
	@intlibID 		INT, 
	@intLocationID 		INT, 
	@strCopyNumber 	VARCHAR(100), 
	@strAcquiredDate	datetime,
	@strRemovedDate	datetime,
	@intReasonID		INT, 
	@dblPrice		FLOAT,
	@strShelf		NVARCHAR(10) ,
	@strVolume		NVARCHAR(32), 
	@intLoanTypeID	INT,
	@intUseCount		INT,
	@intPoID		INT,
	@strDateLastUsed	datetime,
	@strCallNumber		VARCHAR(32),
	@intAcquiredSourceID 	INT,
	@strLiquidCode VARCHAR(2000)
AS
	DECLARE @strSql	NVARCHAR(4000)
	DECLARE @strFieldName VARCHAR(200)
	DECLARE @strFieldValue VARCHAR(200)


	BEGIN TRAN
	INSERT INTO HOLDING_REMOVED 
		(CopyNumber,ItemID, LibID, LocationID,LoanTypeID,Shelf,Price,Reason,AcquiredDate,RemovedDate,Volume,
		UseCount,PoID,DateLastUsed,CallNumber,AcquiredSourceID,LiquidCode)
	VALUES 
		(@strCopyNumber,@intItemID, @intlibID,@intLocationID,@intLoanTypeID,@strShelf,@dblPrice,@intReasonID,@strAcquiredDate,
		@strRemovedDate,@strVolume,@intUseCount,@intPoID,@strDateLastUsed,@strCallNumber,@intAcquiredSourceID,@strLiquidCode)

	UPDATE HOLDING_LOCATION SET MaxNumber = MaxNumber - 1 WHERE ID = @intLocationID
	IF @@ERROR > 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
GO



GO

/****** Object:  StoredProcedure [dbo].[FPT_SP_HOLDING_UPDATE]    Script Date: 8/6/2019 07:55:42 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- intMode = 0: trong kho
-- intMode = 1: dang cho muon
-- intMode = 2: dang khoa
-- intMode = 3: chua kiem nhan



CREATE PROCEDURE [dbo].[FPT_SP_HOLDING_UPDATE]
	@strID NVARCHAR(1000),
	@locid NVARCHAR(1000),
	@libid NVARCHAR(1000),
	@strCopyNumber NVARCHAR(1000),
	@intMode NVARCHAR(1000)
AS
	if @locid <> '' and @libid <> ''
		begin
			IF @intMode = '1' -- kiem nhan 
				EXECUTE('UPDATE HOLDING SET Acquired = 1, LocationID = ' + @locid + ' , LibID = ' + @libid +' , CopyNumber = ''' + @strCopyNumber +'''  WHERE ID =' +@strID)
			else if @intMode = '2' -- mo khoa sach
				EXECUTE('UPDATE HOLDING SET InCirculation = 1, LocationID = ' + @locid + ' , LibID = ' + @libid +' , CopyNumber = ''' + @strCopyNumber +'''   WHERE ID =' +@strID)
			else if @intMode = '3' -- khoa sach
				EXECUTE('UPDATE HOLDING SET InCirculation = 0, LocationID = ' + @locid + ' , LibID = ' + @libid +' , CopyNumber = ''' + @strCopyNumber +'''   WHERE ID =' +@strID)
			else if @intMode = '4' -- cho muon
				EXECUTE('UPDATE HOLDING SET InUsed = 1, LocationID = ' + @locid + ' , LibID = ' + @libid +' , CopyNumber = ''' + @strCopyNumber +'''   WHERE ID =' +@strID)
			else if @intMode = '5' -- thu hoi sach da cho muon
				EXECUTE('UPDATE HOLDING SET InUsed = 0, LocationID = ' + @locid + ' , LibID = ' + @libid +' , CopyNumber = ''' + @strCopyNumber +'''   WHERE ID =' +@strID)
		end
	else
		begin
			IF @intMode = '1' -- kiem nhan 
				EXECUTE('UPDATE HOLDING SET Acquired = 1 '+' , CopyNumber = ''' + @strCopyNumber +''' WHERE ID =' +@strID)
			else if @intMode = '2' -- mo khoa sach
				EXECUTE('UPDATE HOLDING SET InCirculation = 1 '+' , CopyNumber = ''' + @strCopyNumber +''' WHERE ID =' +@strID)
			else if @intMode = '3' -- khoa sach
				EXECUTE('UPDATE HOLDING SET InCirculation = 0 '+' , CopyNumber = ''' + @strCopyNumber +''' WHERE ID =' +@strID)
			else if @intMode = '4' -- cho muon
				EXECUTE('UPDATE HOLDING SET InUsed = 1 '+' , CopyNumber = ''' + @strCopyNumber +''' WHERE ID =' +@strID)
			else if @intMode = '5' -- thu hoi sach da cho muon
				EXECUTE('UPDATE HOLDING SET InUsed = 0 '+' , CopyNumber = ''' + @strCopyNumber +''' WHERE ID =' +@strID)
		end
GO


GO

/****** Object:  StoredProcedure [dbo].[FPT_SP_HOLDING_LIB_SEL]    Script Date: 8/6/2019 07:52:24 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[FPT_SP_HOLDING_LIB_SEL]
	
AS	
	SELECT Code + ': ' + Name as LibName, Code, ID 
	FROM HOLDING_LIBRARY 
	WHERE LocalLib = 1 
	ORDER BY Code
GO

GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_GET_ITEM_INFOR]    Script Date: 07/28/2019 17:31:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<DUCNV>
-- Create date: <Create Date,,>
-- Description:	list item information and count number of copynumber
-- InUsed 
-- =1: dang muon 
-- =============================================
CREATE procedure [dbo].[FPT_SP_GET_ITEM_INFOR] 
	@intItemID int,
	@intLocationID int,
	@intLibraryID int
AS
If @intLocationID <>0
SELECT ItemID, FieldCode, Content, Ind1+ind2 as Indicators FROM Field000s WHERE FieldCode IN (020, 022) AND ItemID = @intItemID
UNION SELECT ItemID, FieldCode, Content, Ind1+ind2 as Indicators FROM Field000s WHERE FieldCode IN (041) AND ItemID = @intItemID
UNION SELECT ItemID, FieldCode, Content, Ind1+ind2 as Indicators FROM Field000s WHERE FieldCode IN (044) AND ItemID = @intItemID
UNION SELECT ItemID, FieldCode, Content, Ind1+ind2 as Indicators FROM Field100s WHERE FieldCode IN (100, 110, 111) AND ItemID = @intItemID
UNION SELECT ItemID, FieldCode, Content, Ind1+ind2 as Indicators FROM Field200s WHERE FieldCode = 245 AND ItemID = @intItemID 
UNION SELECT ItemID, FieldCode, Content, Ind1+ind2 as Indicators FROM Field200s WHERE FieldCode = 250 AND ItemID = @intItemID
UNION SELECT ItemID, FieldCode, Content, Ind1+ind2 as Indicators FROM Field200s WHERE FieldCode = 260 AND ItemID = @intItemID
UNION SELECT ItemID, FieldCode, Content, Ind1+ind2 as Indicators FROM Field300s WHERE FieldCode = 300 AND ItemID = @intItemID
UNION SELECT COUNT(COPYNUMBER) AS ItemID,'soluong' AS FieldCode,'SLuongDKrongKho' AS Content, 'inex' as Indicators FROM HOLDING WHERE ITEMID = @intItemID AND  LocationID =@intLocationID
UNION SELECT COUNT(COPYNUMBER) AS ItemID, 'luongmuon' AS FieldCode,'SLuongDKCBtrongKho' AS Content,'index' as Indicators FROM HOLDING WHERE ITEMID =@intItemID AND  LocationID = @intLocationID
	
If @intLocationID =0
SELECT ItemID, FieldCode, Content, Ind1+ind2 as Indicators FROM Field000s WHERE FieldCode IN (020, 022) AND ItemID = @intItemID
UNION SELECT ItemID, FieldCode, Content, Ind1+ind2 as Indicators FROM Field000s WHERE FieldCode IN (041) AND ItemID = @intItemID
UNION SELECT ItemID, FieldCode, Content, Ind1+ind2 as Indicators FROM Field000s WHERE FieldCode IN (044) AND ItemID = @intItemID
UNION SELECT ItemID, FieldCode, Content, Ind1+ind2 as Indicators FROM Field100s WHERE FieldCode IN (100, 110, 111) AND ItemID = @intItemID
UNION SELECT ItemID, FieldCode, Content, Ind1+ind2 as Indicators FROM Field200s WHERE FieldCode = 245 AND ItemID = @intItemID 
UNION SELECT ItemID, FieldCode, Content, Ind1+ind2 as Indicators FROM Field200s WHERE FieldCode = 250 AND ItemID = @intItemID
UNION SELECT ItemID, FieldCode, Content, Ind1+ind2 as Indicators FROM Field200s WHERE FieldCode = 260 AND ItemID = @intItemID
UNION SELECT ItemID, FieldCode, Content, Ind1+ind2 as Indicators FROM Field300s WHERE FieldCode = 300 AND ItemID = @intItemID
  UNION SELECT COUNT(COPYNUMBER) AS ItemID,'soluong' AS FieldCode,'SLuongDKrongKho' AS Content,'inex' as Indicators FROM HOLDING WHERE ITEMID = @intItemID AND  LibID =@intLibraryID
 UNION SELECT COUNT(COPYNUMBER) AS ItemID,'luongmuon' AS FieldCode,'SLuongDKCBtrongKho' AS Content,'index' as Indicators FROM HOLDING WHERE ITEMID =@intItemID AND  LibID = @intLibraryID

GO
/****** Object:  StoredProcedure [dbo].[FPT_GET_LIQUIDBOOKS_BY_COPYNUMBER]    Script Date: 08/06/2019 17:39:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/******/
CREATE PROCEDURE [dbo].[FPT_GET_LIQUIDBOOKS_BY_COPYNUMBER]
	@strCopyNumber VARCHAR(50)
AS

	DECLARE @strSQL VARCHAR(8000)
	DECLARE @strJoinSQL varchar(1000)
	DECLARE @strLikeSql varchar(1000)
	SET @strSQL = 'SELECT HRR.Reason,
	REPLACE(REPLACE(REPLACE(REPLACE(F.Content,''$a'',''''),''$b'','' ''),''$c'','' ''),''$n'','' '') as Content,
	HR.CopyNumber,
	HR.LiquidCode,
	HR.Price,HR.UseCount,
	HR.RemovedDate' 
	
	SET @strLikeSql = '1 =1 AND '
	SET @strJoinSQL = ''
	
	SET @strJoinSQL = @strJoinSQL + ' FROM HOLDING_REMOVED HR LEFT JOIN FIELD200S F ON HR.ItemID = F.ItemID AND F.FieldCode=''245'' '
	SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN HOLDING_REMOVE_REASON HRR ON HR.Reason=HRR.ID '
	--SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN HOLDING_LIBRARY HL ON HR.LibID = HL.ID '
	--SET @strJoinSQL = @strJoinSQL + ' LEFT JOIN HOLDING_LOCATION HLC ON HR.LocationID = HLC.ID '
		
	IF NOT @strCopyNumber=''
		BEGIN
			SET @strLikeSql=@strLikeSql+' CopyNumber='''+@strCopyNumber+''' AND '
		END
	
	
	SET @strSql = @strSql + @strJoinSQL + ' WHERE ' +@strLikeSQL
	SET @strSql = LEFT(@strSql,LEN(@strSql)-3) 
EXEC(@strSQL)
PRINT(@strSQL)



/****************************** DATA FOR PERMISSION **********************************/
GO
SET IDENTITY_INSERT [dbo].[FPT_SYS_USER_RIGHT] ON 

INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (1, 2, N'FPT - Tra cứu bạn đọc', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (2, 2, N'FPT - Nhập hồ sơ bạn đọc', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (3, 2, N'FPT - Sửa hồ sơ bạn đọc', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (4, 2, N'FPT - Thêm bạn đọc theo lô', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (5, 2, N'FPT - Xóa hồ sơ bạn đọc', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (6, 6, N'FPT - Phân quyền cho phân hệ biên mục', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (7, 6, N'FPT - Phân quyền cho phân hệ bạn đọc', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (8, 6, N'FPT - Phân quyền cho phân hệ mượn trả', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (9, 6, N'FPT - Phân quyền cho phân hệ bổ sung', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (10, 6, N'FPT - Phân quyền cho phân hệ ấn phẩm định kỳ', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (11, 6, N'FPT - Phân quyền cho phân hệ ILL', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (12, 6, N'FPT - Phân quyền cho phân hệ phát hành', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (13, 1, N'FPT - Tạo mới bản ghi biên mục', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (15, 1, N'FPT - Sửa bản ghi biên mục', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (16, 3, N'FPT- Ghi mượn', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (17, 3, N'FPT - Ghi trả', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (18, 3, N'FPT - Gia hạn', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (19, 3, N'FPT - Khoá thẻ', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (20, 3, N'FPT - Quá hạn', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (21, 3, N'FPT - Báo cáo', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (23, 3, N'FPT - Thống kê', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (25, 3, N'FPT - Kiểm tra thanh lý', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (26, 4, N'FPT - Xếp giá', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (27, 4, N'FPT - Báo cáo', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (28, 4, N'FPT - Thống kê', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (29, 4, N'FPT - Kho', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (30, 4, N'FPT - In mã vạch', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (31, 4, N'FPT - In nhãn gáy', 1)
INSERT [dbo].[FPT_SYS_USER_RIGHT] ([ID], [ModuleID], [Right], [IsBasic]) VALUES (32, 4, N'FPT - Thanh lý', 1)
SET IDENTITY_INSERT [dbo].[FPT_SYS_USER_RIGHT] OFF
SET IDENTITY_INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ON 

INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (13, 1, 31)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (15, 1, 32)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (1, 1, 33)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (2, 1, 34)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (3, 1, 35)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (4, 1, 36)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (5, 1, 37)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (16, 1, 38)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (17, 1, 39)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (18, 1, 40)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (19, 1, 41)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (20, 1, 42)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (21, 1, 43)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (23, 1, 44)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (25, 1, 45)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (26, 1, 46)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (27, 1, 47)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (28, 1, 48)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (29, 1, 49)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (30, 1, 50)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (31, 1, 51)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (32, 1, 52)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (6, 1, 53)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (7, 1, 54)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (8, 1, 55)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (9, 1, 56)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (10, 1, 57)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (11, 1, 58)
INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] ([RightID], [UserID], [ID]) VALUES (12, 1, 59)
SET IDENTITY_INSERT [dbo].[FPT_SYS_USER_RIGHT_DETAIL] OFF




GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_STAT_PATRONGROUP]    Script Date: 7/10/2019 06:20:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create PROCEDURE [dbo].[FPT_SP_STAT_PATRONGROUP]
	-- Created Tuanhv
	-- Date 06/09/2004
	-- ModifyDate:
	@intUserID varchar(30),
	@strCheckOutDateFrom varchar(30),
	@strCheckOutDateTo varchar(30),
	@OptItemID varchar(30), --0 la thong ke theo dau an pham, 1 la thong ke tho DKCB
	@intHistory varchar(30), --0 la hien tai dang muon
	@LibID varchar(30)
AS
	DECLARE @StrSql varchar(1500),
			@userid int,
			@itemid int,
			@history int

			SET @userid = CAST(@intUserID as int)
			SET @itemid = CAST(@OptItemID as int)
			SET @history = CAST(@intHistory as int)

IF @history = 0 
BEGIN

	SET @StrSql = ''
	IF @itemid <> 0 
	BEGIN
		SET @StrSql = 	' SELECT Count (CL.ItemID) AS TotalLoan, CPG.Name ' +
				' FROM CIR_LOAN CL LEFT JOIN CIR_PATRON CP ON CP.ID = CL.PatronID ' + 
				' JOIN CIR_PATRON_GROUP CPG ON CP.PatronGroupID = CPG.ID ' +
				' WHERE 1=1 '
	END
	ELSE
	BEGIN
		SET @StrSql = 	' SELECT Count (DISTINCT CL.ItemID) AS TotalLoan, CPG.Name ' +
				' FROM CIR_LOAN CL LEFT JOIN CIR_PATRON CP ON CP.ID = CL.PatronID ' + 
				' JOIN CIR_PATRON_GROUP CPG ON CP.PatronGroupID = CPG.ID ' +
				' WHERE 1=1 '
	END

	IF @strCheckOutDateFrom <> ''
		SET @StrSql = @StrSql +  ' AND CL.CheckOutDate >=''' + @strCheckOutDateFrom +''''
	IF @strCheckOutDateTo <> ''
		SET @StrSql = @StrSql +  ' AND CL.CheckOutDate <=''' + @strCheckOutDateTo +''''

	SET @strSql = @strSql + ' AND CL.LocationID IN 
	( SELECT B.ID AS ID 
	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C 
	WHERE A.ID = ' + @LibID + ' AND A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@userid AS CHAR(20)) + ' ) '

	SET @StrSql = @StrSql + ' GROUP BY CPG.Name ORDER BY Count (CL.ItemID) '	
END 
ELSE
BEGIN
	SET @StrSql = ''
	IF @itemid <> 0 
	BEGIN
		SET @StrSql = 	' SELECT Count (CLH.ItemID) AS TotalLoan, CPG.Name ' +
				' FROM CIR_LOAN_HISTORY CLH LEFT JOIN CIR_PATRON CP ON CP.ID = CLH.PatronID ' + 
				' JOIN CIR_PATRON_GROUP CPG ON CP.PatronGroupID = CPG.ID ' +
				' WHERE 1=1 '
	END
	ELSE
	BEGIN
		SET @StrSql = 	' SELECT Count (DISTINCT CLH.ItemID) AS TotalLoan, CPG.Name ' +
				' FROM CIR_LOAN_HISTORY CLH LEFT JOIN CIR_PATRON CP ON CP.ID = CLH.PatronID ' + 
				' JOIN CIR_PATRON_GROUP CPG ON CP.PatronGroupID = CPG.ID ' +
				' WHERE 1=1 '
	END

	IF @strCheckOutDateFrom <> ''
		SET @StrSql = @StrSql +  ' AND CLH.CheckOutDate >=''' + @strCheckOutDateFrom +''''
	IF @strCheckOutDateTo <> ''
		SET @StrSql = @StrSql +  ' AND CLH.CheckOutDate <=''' + @strCheckOutDateTo +''''

	SET @strSql = @strSql + ' AND CLH.LocationID IN ( 
	SELECT B.ID AS ID 
	FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C 
	WHERE A.ID = ' + @LibID + ' AND A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@userid AS CHAR(20)) + ' ) '

	SET @StrSql = @StrSql + ' GROUP BY CPG.Name ORDER BY Count (CLH.ItemID) '	

END
	EXEC (@StrSql)






GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_STAT_ITEMMAX]    Script Date: 7/10/2019 06:22:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create PROCEDURE [dbo].[FPT_SP_STAT_ITEMMAX]
	-- Created Tuanhv
	-- Date 06/09/2004
	-- ModifyDate:
	@intUserID varchar(30),
	@strCheckOutDateFrom varchar(30),
	@strCheckOutDateTo varchar(30),
	@intTopNum varchar(30),
	@intMinLoan varchar(30),
	@libid varchar(30),
	@locid varchar(30)
AS
DECLARE @StrSql varchar(1500)
	SET @StrSql = ''
	SET @StrSql = @StrSql + 
	' SELECT TOP ' + @intTopNum + ' Count (*) AS TotalLoan, CLH.CopyNumber AS Name  
	FROM CIR_LOAN_HISTORY CLH 
	WHERE 1=1 ' 
	IF @strCheckOutDateFrom <> ''
		SET @StrSql = @StrSql +  ' AND CLH.CheckOutDate >=''' + @strCheckOutDateFrom +''''
	IF @strCheckOutDateTo <> ''
		SET @StrSql = @StrSql +  ' AND CLH.CheckOutDate <=''' + @strCheckOutDateTo +''''

		IF @locid <>'0'
		begin
		SET @StrSql = @StrSql + ' AND CLH.LocationID IN 
		( SELECT B.ID AS ID 
		FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C 
		WHERE A.ID = ' + CAST(@libid as varchar(30))+' and A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID = ' 
		+ @intUserID+ ' and B.ID = ' + @locid + ' ) '
		end
		else 
		begin 
		SET @StrSql = @StrSql + ' AND CLH.LocationID IN 
		( SELECT B.ID AS ID 
		FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C 
		WHERE A.ID = ' + CAST(@libid as varchar(30))+' and A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID = ' + @intUserID+ ' ) '
		end

		SET @StrSql = @StrSql + ' GROUP BY CLH.CopyNumber  HAVING Count (*) >= ' + @intMinLoan + ' ORDER BY TotalLoan DESC'
	EXEC (@StrSql)





GO
/****** Object:  StoredProcedure [dbo].[FPT_SP_STAT_PATRONMAX]    Script Date: 7/10/2019 06:18:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[FPT_SP_STAT_PATRONMAX]
	-- Created Tuanhv
	-- Date 06/09/2004
	-- ModifyDate:
	@intUserID varchar(30),
	@strCheckOutDateFrom varchar(30),
	@strCheckOutDateTo varchar(30),
	@intTopNum varchar(30),
	@intMinLoan varchar(30),
	@OptItemID varchar(30), --0 la thong ke theo dau an pham, 1 la thong ke tho DKCB
	@LocID varchar(30),
	@LibID varchar(30)

AS
DECLARE @StrSql varchar(1500),
		@user_id int,
		@top_num int,
		@min_loan int,
		@opt_item_id int,
		@loc_id int,
		@lib_id int

	SET @StrSql = ''
	SET @user_id = CAST(@intUserID as int)
	SET @top_num = CAST(@intTopNum as int)
	SET @min_loan = CAST(@intMinLoan as int)
	SET @opt_item_id = CAST(@OptItemID as int)
	SET @loc_id = CAST(@LocID as int)
	SET @lib_id = CAST(@LibID as int)

	IF @loc_id = 0
	BEGIN
		IF @opt_item_id <> 0 
		SET @StrSql = @StrSql + ' SELECT TOP ' + CAST(@top_num AS CHAR(10)) + 
		'Count (*) AS TotalLoan, CP.Code AS Name  FROM CIR_LOAN_HISTORY CLH, CIR_PATRON CP  WHERE 1=1 AND CP.ID = CLH.PatronID ' 
		ELSE SET @StrSql = @StrSql + ' SELECT TOP ' + CAST(@top_num AS CHAR(10)) + 'Count (DISTINCT Copynumber) AS TotalLoan, CP.Code AS Name FROM CIR_LOAN_HISTORY CLH, CIR_PATRON CP  WHERE 1=1 AND CP.ID = CLH.PatronID ' 							
		IF @strCheckOutDateFrom <> ''SET @StrSql = @StrSql +  ' AND CLH.CheckOutDate >=''' + @strCheckOutDateFrom +''''
		IF @strCheckOutDateTo <> ''SET @StrSql = @StrSql +  ' AND CLH.CheckOutDate <=''' + @strCheckOutDateTo +''''		
		IF @opt_item_id <> 0
		BEGIN
			SET @strSql = @strSql + ' AND CLH.LocationID IN 
			( SELECT B.ID AS ID 
			FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C 
			WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID 
			AND C.UserID =' + CAST(@user_id AS CHAR(20)) + ' AND A.ID = ' + CAST(@lib_id AS CHAR(20)) + ' ) '
			SET @StrSql = @StrSql + ' GROUP BY CP.Code  HAVING Count (*) >=' + CAST(@min_loan AS CHAR(5)) + ' ORDER BY TotalLoan DESC'
		END
		ELSE
		BEGIN
			SET @strSql = @strSql + ' AND CLH.LocationID IN 
			( SELECT B.ID AS ID 
			FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C 
			WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID 
			AND C.UserID =' + CAST(@user_id AS CHAR(20)) + ' AND A.ID = ' + CAST(@lib_id AS CHAR(20)) + ' ) '
       	    SET @StrSql = @StrSql + ' GROUP BY CP.Code  HAVING Count (DISTINCT Copynumber) >=' + CAST(@min_loan AS CHAR(5)) + ' ORDER BY TotalLoan DESC' 
		END
	END
	ELSE
	BEGIN
		IF @opt_item_id <> 0 
		SET @StrSql = @StrSql + ' SELECT TOP ' + CAST(@top_num AS CHAR(10)) + 
		'Count (*) AS TotalLoan, CP.Code AS Name  
		FROM CIR_LOAN_HISTORY CLH, CIR_PATRON CP  
		WHERE 1=1 AND CP.ID = CLH.PatronID ' 
		ELSE 
		SET @StrSql = @StrSql + ' SELECT TOP ' + CAST(@top_num AS CHAR(10)) + 
		'Count (DISTINCT Copynumber) AS TotalLoan, CP.Code AS Name 
		FROM CIR_LOAN_HISTORY CLH, CIR_PATRON CP  
		WHERE 1=1 AND CP.ID = CLH.PatronID ' 							
		IF @strCheckOutDateFrom <> ''
		SET @StrSql = @StrSql +  ' AND CLH.CheckOutDate >=''' + @strCheckOutDateFrom +''''
		IF @strCheckOutDateTo <> ''
		SET @StrSql = @StrSql +  ' AND CLH.CheckOutDate <=''' + @strCheckOutDateTo +''''		
		IF @opt_item_id <> 0
		BEGIN
			SET @strSql = @strSql + ' AND CLH.LocationID IN 
			( SELECT B.ID AS ID 
			FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C 
			WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID 
			AND C.UserID =' + CAST(@user_id AS CHAR(20)) + ' AND B.ID = ' + CAST(@loc_id AS CHAR(20)) + ' ) '
			SET @StrSql = @StrSql + ' GROUP BY CP.Code  HAVING Count (*) >=' + CAST(@min_loan AS CHAR(5)) + ' ORDER BY TotalLoan DESC'
		END
		ELSE
		BEGIN
			SET @strSql = @strSql + ' AND CLH.LocationID IN 
			( SELECT B.ID AS ID 
			FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C 
			WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID 
			AND C.UserID =' + CAST(@user_id AS CHAR(20)) + ' AND B.ID = ' + CAST(@loc_id AS CHAR(20)) + ' ) '
       	    SET @StrSql = @StrSql + ' GROUP BY CP.Code  HAVING Count (DISTINCT Copynumber) >=' + CAST(@min_loan AS CHAR(5)) + ' ORDER BY TotalLoan DESC' 
		END
	END


	EXEC (@StrSql)



GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	THỐNG KÊ TOP 20 THEO TÁC GIẢ
-- =============================================
CREATE PROCEDURE [dbo].[FPT_ACQ_STATISTIC_TOP20]
	@intType int,
	@intCategoryID int
AS
BEGIN 
	IF @intCategoryID = 1 -- TOP20 AUTHOR
	BEGIN
		IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM HOLDING A,ITEM_AUTHOR B,CAT_DIC_AUTHOR C 
			WHERE B.AuthorID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ')AS AccessEntry 
				FROM ITEM_AUTHOR B,CAT_DIC_AUTHOR C 
			WHERE B.AuthorID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	END
	ELSE IF @intCategoryID = 2 -- TOP20 PUBLISHER
	BEGIN
		IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM HOLDING A,ITEM_PUBLISHER B,CAT_DIC_PUBLISHER C 
			WHERE B.PublisherID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$b'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_PUBLISHER B,CAT_DIC_PUBLISHER C 
			WHERE B.PublisherID=C.ID AND Right(B.Fieldcode,2)='$b'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	END
	ELSE IF @intCategoryID = 3 -- TOP20 KEYWORD
	BEGIN
		IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM HOLDING A,ITEM_KEYWORD B,CAT_DIC_KEYWORD C 
			WHERE B.KeyWordID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_KEYWORD B,CAT_DIC_KEYWORD C 
			WHERE B.KeyWordID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	END
	ELSE IF @intCategoryID = 4 -- TOP20 BBK
	BEGIN
		IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_BBK B,CAT_DIC_CLASS_BBK C 
			WHERE B.BBKID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_BBK B,CAT_DIC_CLASS_BBK C 
			WHERE B.BBKID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	END
	ELSE IF @intCategoryID = 5 -- TOP20 DDC
	BEGIN
		IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_DDC B,CAT_DIC_CLASS_DDC C 
			WHERE B.DDCID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_DDC B,CAT_DIC_CLASS_DDC C 
			WHERE B.DDCID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	END
	ELSE IF @intCategoryID = 6 -- TOP20 LOC
	BEGIN
		IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_LOC B,CAT_DIC_CLASS_LOC C 
			WHERE B.LOCID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_LOC B,CAT_DIC_CLASS_LOC C 
			WHERE B.LOCID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	END
	ELSE IF @intCategoryID = 7 -- TOP20 UDC
	BEGIN
		IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_UDC B,CAT_DIC_CLASS_UDC C 
			WHERE B.UDCID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_UDC B,CAT_DIC_CLASS_UDC C 
			WHERE B.UDCID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	END
	ELSE IF @intCategoryID = 9 -- TOP20 SH
	BEGIN
		IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM HOLDING A,ITEM_SH B,CAT_DIC_SH C 
				WHERE B.SHID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ')AS AccessEntry 
				FROM ITEM_SH B,CAT_DIC_SH C 
				WHERE B.SHID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	END
	ELSE IF @intCategoryID = 10 -- TOP20 LANGUAGE
	BEGIN
		IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_LANGUAGE B,CAT_DIC_LANGUAGE C 
			WHERE B.LanguageID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_LANGUAGE B,CAT_DIC_LANGUAGE C 
			WHERE B.LanguageID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	END
	ELSE IF @intCategoryID = 11 -- TOP20 COUNTRY
	BEGIN
		IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_COUNTRY B,CAT_DIC_COUNTRY C 
			WHERE B.CountryID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_COUNTRY B,CAT_DIC_COUNTRY C 
			WHERE B.CountryID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	END
	ELSE IF @intCategoryID = 12 -- TOP20 SERIAL
	BEGIN
		IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_SERIES B,CAT_DIC_SERIES C 
			WHERE B.SeriesID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_SERIES B,CAT_DIC_SERIES C 
			WHERE B.SeriesID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	END
	ELSE IF @intCategoryID = 14 -- TOP20 MEDIUM
	BEGIN
		IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 A.TOTAL as Total, B.CODE, B.NAME as AccessEntry FROM(SELECT COUNT(I.MEDIUMID) AS TOTAL, I.MEDIUMID AS ID
			FROM HOLDING H, ITEM I WHERE H.ITEMID = I.ID
			GROUP BY I.MEDIUMID) A, (SELECT DISTINCT(I.MEDIUMID) AS ID, C.CODE AS CODE, ISNULL(C.DESCRIPTION,C.ACCESSENTRY) AS NAME FROM ITEM I, CAT_DIC_MEDIUM C WHERE I.MEDIUMID = C.ID) B
			WHERE A.ID = B.ID
			ORDER BY A.TOTAL DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 A.TOTAL as Total, B.CODE, B.NAME as AccessEntry FROM(SELECT COUNT(I.MEDIUMID) AS TOTAL, I.MEDIUMID AS ID
			FROM ITEM I
			GROUP BY I.MEDIUMID) A, (SELECT DISTINCT(I.MEDIUMID) AS ID, C.CODE AS CODE, ISNULL(C.DESCRIPTION,C.ACCESSENTRY) AS NAME FROM ITEM I, CAT_DIC_MEDIUM C WHERE I.MEDIUMID = C.ID) B
			WHERE A.ID = B.ID
			ORDER BY A.TOTAL DESC
		END
	END
	ELSE IF @intCategoryID = 17 -- TOP20 ITEMTYPE
	BEGIN
		IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 A.TOTAL AS Total, B.CODE AS AccessEntry, B.NAME FROM(SELECT COUNT(H.ITEMID) AS TOTAL, I.TYPEID AS ID
			FROM HOLDING H, ITEM I WHERE H.ITEMID = I.ID
			GROUP BY I.TYPEID) A, (SELECT DISTINCT(I.TYPEID) AS ID, C.TYPECODE AS CODE, ISNULL(C.TYPENAME,'Không XĐ') AS NAME FROM ITEM I, CAT_DIC_ITEM_TYPE C WHERE I.TYPEID = C.ID) B
			WHERE A.ID = B.ID
			ORDER BY A.TOTAL DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 A.TOTAL as Total, B.CODE AS AccessEntry, B.NAME FROM(SELECT COUNT(DISTINCT H.ITEMID) AS TOTAL, I.TYPEID AS ID
			FROM HOLDING H, ITEM I WHERE H.ITEMID = I.ID
			GROUP BY I.TYPEID) A, (SELECT DISTINCT(I.TYPEID) AS ID, C.TYPECODE AS CODE, ISNULL(C.TYPENAME,'Không XĐ') AS NAME 
			FROM ITEM I, CAT_DIC_ITEM_TYPE C WHERE I.TYPEID = C.ID) B
			WHERE A.ID = B.ID
			ORDER BY A.TOTAL DESC
		END
	END
	ELSE IF @intCategoryID = 18 -- TOP20 LIBRARY
	BEGIN
		IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 A.TOTAL AS Total, B.CODE AS AccessEntry, B.NAME FROM(SELECT COUNT(H.ITEMID) AS TOTAL, H.LIBID AS ID
			FROM HOLDING H, ITEM I WHERE H.ITEMID = I.ID
			GROUP BY H.LIBID) A, (SELECT DISTINCT(H.LIBID) AS ID, L.CODE AS CODE, ISNULL(L.ACCESSENTRY,'Không XĐ') AS NAME FROM HOLDING H, HOLDING_LIBRARY L WHERE H.LIBID = L.ID) B
			WHERE A.ID = B.ID
			ORDER BY A.TOTAL DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 A.TOTAL AS Total, B.CODE AS AccessEntry, B.NAME FROM(SELECT COUNT(DISTINCT H.ITEMID) AS TOTAL, H.LIBID AS ID
			FROM HOLDING H, ITEM I WHERE H.ITEMID = I.ID
			GROUP BY H.LIBID) A, (SELECT DISTINCT(H.LIBID) AS ID, L.CODE AS CODE, ISNULL(L.ACCESSENTRY,'Không XĐ') AS NAME FROM HOLDING H, HOLDING_LIBRARY L WHERE H.LIBID = L.ID) B
			WHERE A.ID = B.ID
			ORDER BY A.TOTAL DESC
		END
	END
	ELSE IF @intCategoryID = 19 -- TOP20 THESIS SUBJECT
	BEGIN
		IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_THESIS_SUBJECT B,CAT_DIC_THESIS_SUBJECT C 
			WHERE B.SubjectID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_THESIS_SUBJECT B,CAT_DIC_THESIS_SUBJECT C 
			WHERE B.SubjectID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	END
	ELSE IF @intCategoryID = 30 -- TOP20 NLM
	BEGIN
		IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_NLM B,CAT_DIC_CLASS_NLM C 
			WHERE B.NLMID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_NLM B,CAT_DIC_CLASS_NLM C 
			WHERE B.NLMID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	END
	ELSE IF @intCategoryID = 31 -- TOP20 OAI SET
	BEGIN
		IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_OAI_SET B,CAT_DIC_OAI_SET C 
			WHERE B.OaiID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_OAI_SET B,CAT_DIC_OAI_SET C 
			WHERE B.OaiID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	END
	--ELSE IF @intCategoryID = 38 -- TOP20 NOI XUAT BAN
	--BEGIN
	--END
	ELSE IF @intCategoryID = 40 -- TOP20 DIC40
	BEGIN
		IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_DICTIONARY40 B,DICTIONARY40 C 
			WHERE B.DICTIONARY40ID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_DICTIONARY40 B,DICTIONARY40 C 
			WHERE B.DICTIONARY40ID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	END
	ELSE IF @intCategoryID = 41 -- TOP20 DIC41
	BEGIN
			IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_DICTIONARY41 B,DICTIONARY41 C 
			WHERE B.DICTIONARY41ID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_DICTIONARY41 B,DICTIONARY41 C 
			WHERE B.DICTIONARY41ID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	END
	ELSE IF @intCategoryID = 42 -- TOP20 DIC42
	BEGIN
		IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_DICTIONARY42 B,DICTIONARY42 C 
			WHERE B.DICTIONARY42ID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$c'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_DICTIONARY42 B,DICTIONARY42 C 
			WHERE B.DICTIONARY42ID=C.ID AND Right(B.Fieldcode,2)='$c'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	END
	ELSE IF @intCategoryID = 43 -- TOP20 DIC43
	BEGIN
		IF @intType = 1 -- THỐNG KÊ THEO BẢN ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry
				FROM HOLDING A,ITEM_DICTIONARY43 B,DICTIONARY43 C 
			WHERE B.DICTIONARY43ID=C.ID AND A.ItemID=B.ItemID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
		ELSE	-- THỐNG KÊ THEO ĐẦU ẤN PHẨM
		BEGIN
			SELECT TOP 20 sum(A.Total) as Total,A.AccessEntry 
			FROM (SELECT Count(*) AS Total,ISNULL(C.AccessEntry,'Không XĐ') AS AccessEntry 
				FROM ITEM_DICTIONARY43 B,DICTIONARY43 C 
			WHERE B.DICTIONARY43ID=C.ID AND Right(B.Fieldcode,2)='$a'  GROUP BY C.AccessEntry) A 
			GROUP BY A.AccessEntry ORDER BY Total DESC
		END
	END	
END


	--DOANHDQ
GO

/****** Object:  Table [dbo].[FPT_CATA_FILE_NEW]    Script Date: 8/16/2019 12:49:26 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[FPT_CATA_FILE_NEW](
	[ID] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[ItemID] [int] NOT NULL FOREIGN KEY REFERENCES Item(ID),
	[FileName] [nvarchar](250) NULL,
	[FilePath] [nvarchar](250) NULL
)


GO
/****** Object:  StoredProcedure [dbo].[FPT_CIR_SP_STAT_TOP20]    Script Date: 08/22/2019 11:49:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--SP_STAT_TOP20 0,30,14
Create    PROCEDURE [dbo].[FPT_CIR_SP_STAT_TOP20] 
	@intHistory int, --1 la thong ke lich su muon sach.  
	@intID int,  
	@intUserID int,
	@intLibID int  
AS   
DECLARE @StrSql Varchar(4000)  
DECLARE @strIndexTable varchar(50)   
DECLARE @strIndexIDField varchar(50)  
DECLARE @strDicTable varchar(50)  
DECLARE @strCaptionField varchar(50)  
DECLARE @strDicIDField varchar(50)  
	SELECT @strIndexTable = IndexTable, @strIndexIDField = IndexIDField, @strDicTable = DicTable, @strCaptionField = CaptionField, @strDicIDField = DicIDField FROM CAT_DIC_LIST WHERE IndexTable IS NOT NULL AND ID = @intID  
	SET @StrSql = ''  
	IF @intHistory = 1   
	BEGIN  
		IF @intID IN (2,36)
			SET @StrSql = ' SELECT A.Total, A.Label, A.Name FROM (SELECT TOP 20 Count (*) AS Total, ' + @strIndexIDField + ' AS Label, ' + @strDicTable + '.' + @strCaptionField + ' as Name From CIR_LOAN_HISTORY,' +  @strIndexTable + ',' + @strDicTable + ' WHERE CIR_LOAN_HISTORY.ItemID =  ' + @strIndexTable +'.ItemID AND RIGHT(' +  @strIndexTable +'.FieldCode,2)=''$b'''    
		ELSE
			IF @intID = 34
				SET @StrSql = ' SELECT A.Total, A.Label, A.Name FROM (SELECT TOP 20 Count (*) AS Total, ' + @strIndexIDField + ' AS Label, ' + @strDicTable + '.' + @strCaptionField + ' as Name From CIR_LOAN_HISTORY,' +  @strIndexTable + ',' + @strDicTable + ' WHERE CIR_LOAN_HISTORY.ItemID =  ' + @strIndexTable +'.ItemID AND RIGHT(' +  @strIndexTable +'.FieldCode,2)=''$c'''    
			ELSE
				SET @StrSql = ' SELECT A.Total, A.Label, A.Name FROM (SELECT TOP 20 Count (*) AS Total, ' + @strIndexIDField + ' AS Label, ' + @strDicTable + '.' + @strCaptionField + ' as Name From CIR_LOAN_HISTORY,' +  @strIndexTable + ',' + @strDicTable + ' WHERE CIR_LOAN_HISTORY.ItemID =  ' + @strIndexTable +'.ItemID AND RIGHT(' +  @strIndexTable +'.FieldCode,2)=''$a'''    
		SET @StrSql =  @StrSql + ' AND ' + @strDicTable + '.' + @strDicIDField + ' = ' + @strIndexTable + '.' + @strIndexIDField   
		IF @intLibID <> 0
		SET @StrSql =  @StrSql + ' AND CIR_LOAN_HISTORY.LocationID IN ( SELECT B.ID AS ID FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND LibID =' + CAST(@intLibID AS CHAR(20)) + ' AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) '   
		ELSE
		SET @StrSql =  @StrSql + ' AND CIR_LOAN_HISTORY.LocationID IN ( SELECT B.ID AS ID FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) '   
		
		SET @StrSql =  @StrSql +   ' GROUP BY ' + @strIndexIDField + ',' +  @strDicTable + '.' + @strCaptionField  + ' ORDER BY Total DESC) A '  
	END  
	ELSE  
		IF @intHistory = 0  
			BEGIN  
			IF @intID IN (2,36)
				SET @StrSql = ' SELECT A.Total, A.Label, A.Name FROM (SELECT TOP 20 Count (*) as Total, ' + @strIndexIDField + ' AS Label, ' + @strDicTable + '.' + @strCaptionField + ' as Name From CIR_LOAN,' +  @strIndexTable + ',' + @strDicTable + ' WHERE CIR_LOAN.ItemID =  ' + @strIndexTable +'.ItemID AND RIGHT(' +  @strIndexTable +'.FieldCode,2)=''$b''' 
			ELSE
				IF @intID = 34
					SET @StrSql = ' SELECT A.Total, A.Label, A.Name FROM (SELECT TOP 20 Count (*) AS Total, ' + @strIndexIDField + ' AS Label, ' + @strDicTable + '.' + @strCaptionField + ' as Name From CIR_LOAN_HISTORY,' +  @strIndexTable + ',' + @strDicTable + ' WHERE CIR_LOAN_HISTORY.ItemID =  ' + @strIndexTable +'.ItemID AND RIGHT(' +  @strIndexTable +'.FieldCode,2)=''$c'''    
				ELSE
					SET @StrSql = ' SELECT A.Total, A.Label, A.Name FROM (SELECT TOP 20 Count (*) as Total, ' + @strIndexIDField + ' AS Label, ' + @strDicTable + '.' + @strCaptionField + ' as Name From CIR_LOAN,' +  @strIndexTable + ',' + @strDicTable + ' WHERE CIR_LOAN.ItemID =  ' + @strIndexTable +'.ItemID AND RIGHT(' +  @strIndexTable +'.FieldCode,2)=''$a''' 
			SET @StrSql =  @StrSql + ' AND ' + @strDicTable + '.' + @strDicIDField + ' = ' + @strIndexTable + '.' + @strIndexIDField   
			IF @intID = 34
				IF @intLibID <> 0
					SET @StrSql =  @StrSql + ' AND CIR_LOAN_HISTORY.LocationID IN ( SELECT B.ID AS ID FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND LibID =' + CAST(@intLibID AS CHAR(20)) + ' AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) '   
				ELSE
					SET @StrSql =  @StrSql + ' AND CIR_LOAN_HISTORY.LocationID IN ( SELECT B.ID AS ID FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) '   
			
			ELSE
				IF @intLibID <> 0
					SET @StrSql =  @StrSql + ' AND CIR_LOAN.LocationID IN ( SELECT B.ID AS ID FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND LibID =' + CAST(@intLibID AS CHAR(20)) + ' AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) '   
				ELSE
					SET @StrSql =  @StrSql + ' AND CIR_LOAN.LocationID IN ( SELECT B.ID AS ID FROM HOLDING_LIBRARY A, HOLDING_LOCATION B, SYS_USER_CIR_LOCATION C WHERE A.LocalLib = 1 AND A.ID = B.LibID AND B.ID = C.LocationID AND C.UserID =' + CAST(@intUserID AS CHAR(20)) + ' ) '   
			SET @StrSql =  @StrSql +   ' GROUP BY ' + @strIndexIDField + ',' +  @strDicTable + '.' + @strCaptionField  + ' ORDER BY Total DESC) A '  
		END     
	EXEC(@StrSql)
print(@StrSql)
Go


