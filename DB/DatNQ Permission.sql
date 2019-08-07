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


CREATE PROCEDURE [dbo].[FPT_ADMIN_GET_RIGHTS_ACCEPT]
	@intModuleID int,
	@intUserID int
AS
SELECT R.ID, R.[Right] FROM FPT_SYS_USER_RIGHT_DETAIL D JOIN FPT_SYS_USER_RIGHT R ON D.RightID = R.ID
WHERE D.UserID = @intUserID AND R.ModuleID = @intModuleID

GO
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

GO
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

GO

CREATE PROCEDURE [dbo].[FPT_SP_ADMIN_GRANT_RIGHTS]
	@intUID int,
	@intRightID int
AS
	INSERT INTO FPT_SYS_USER_RIGHT_DETAIL (UserID, RightID) VALUES (@intUID,@intRightID)
GO



GO

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