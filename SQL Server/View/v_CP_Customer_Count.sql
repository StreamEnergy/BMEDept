USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_CP_Customer_Count]    Script Date: 08/26/2014 13:34:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
						
08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/

CREATE VIEW [dbo].[v_CP_Customer_Count]
AS
    SELECT  COUNT(DISTINCT c.LDCNo) AS CustCnt ,
            c.Commodity ,
            c.State ,
            c.PremiseType ,
            c.LDCName
    FROM    customerprofile c
    WHERE   -- cast(getdate() as date) between c.BeginServiceDate and ISNULL(c.EndServiceDate,'12/31/2999') --and c.State = 'MD' and c.LDCName = 'BGE' --and PremiseType = 'R'
            c.BeginServiceDate <> ISNULL(c.EndServiceDate , '12/31/2999')
--and c.LDCNo <> '3000242769-0138362739'
GROUP BY    c.Commodity ,
            c.State ,
            c.PremiseType ,
            c.LDCName
--order by c.State, c.LDCName, c.PremiseType, c.Commodity





GO


