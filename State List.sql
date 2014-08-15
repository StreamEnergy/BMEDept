USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[Rpt_State_List]    Script Date: 07/17/2014 13:51:36 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Rpt_State_List]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Rpt_State_List]
GO

USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[Rpt_MasTATErket_List]    Script Date: 07/17/2014 13:51:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Jide Akintoye>
-- Create date: <07/17/2014>
-- Description:	<Description of Market list, ID and State Abbr.>
-- =============================================
create PROCEDURE [dbo].[Rpt_State_List]
AS
BEGIN

SELECT [MarketId]
      ,[StateAbbr]
      ,[State]
  FROM Temp_Market_List

END



GO


