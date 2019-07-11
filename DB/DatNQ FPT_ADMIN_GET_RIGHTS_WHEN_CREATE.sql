CREATE PROCEDURE [dbo].[FPT_ADMIN_GET_RIGHTS_WHEN_CREATE]
	@intModuleID int,
	@intParentID int,
	@IsBasic int
AS

SELECT R.ID, R.[Right] FROM SYS_USER_RIGHT R 
JOIN SYS_USER_RIGHT_DETAIL D ON R.ID = D.RightID 
JOIN SYS_USER E ON D.UserID = E.ID 
WHERE D.UserID = @intParentID AND R.ModuleID = @intModuleID AND R.IsBasic = @IsBasic