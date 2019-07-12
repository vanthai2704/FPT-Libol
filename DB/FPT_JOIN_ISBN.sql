USE [Libol]
GO
/****** Object:  StoredProcedure [dbo].[FPT_JOIN_ISBN]    Script Date: 07/12/2019 10:55:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[FPT_JOIN_ISBN] (@itemid int)
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
