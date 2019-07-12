USE [Libol]
GO
/****** Object:  StoredProcedure [dbo].[FPT_CHECK_ITEMID_AND_ACQUIREDATE]    Script Date: 07/12/2019 09:13:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[FPT_CHECK_ITEMID_AND_ACQUIREDATE](@LocID int, @CDate date, @itemId int)
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	select ItemID  from Holding 
where AcquiredDate < CONVERT (varchar(10), @CDate, 21) and ItemID = @itemId and LocationID = @LocID
END
