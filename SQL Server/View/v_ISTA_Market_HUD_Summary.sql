USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_ISTA_Market_HUD_Summary]    Script Date: 08/26/2014 15:10:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
						Eric McCormick						Generate the average daily market HUD by premise.
															Development Notes:	
															This view is to be used by the v_ISTA_Customers view.
08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/



CREATE VIEW [dbo].[v_ISTA_Market_HUD_Summary]
AS
    SELECT  [PremNo] ,
            AVG([DailyAvgConsumption]) AS DailyAvgConsumption
    FROM    [StreamInternal].[dbo].[v_ISTA_Market_HUD]
    GROUP BY [PremNo]





GO


