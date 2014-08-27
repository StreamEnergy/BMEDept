USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_Customer_Count_Detail]    Script Date: 08/26/2014 13:35:32 ******/
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


CREATE VIEW [dbo].[v_Customer_Count_Detail]
AS
    SELECT  m.state STATE ,
            COUNT(DISTINCT p.CustID) AS CUST_COUNT ,
            p.statusid STATUS_ID ,
            ps.status STATUS ,
            CONVERT(VARCHAR(10) , GETDATE() , 101) AS AS_OF_DATE
    FROM    stream.dbo.premise p
    LEFT JOIN stream.dbo.PremiseStatus ps ON p.StatusID = ps.PremiseStatusID
    LEFT JOIN stream.dbo.LDCLookup l ON l.LDCID = p.LDCID
    LEFT JOIN StreamInternal.dbo.market m ON l.MarketID = m.MarketID
    WHERE   p.StatusID NOT IN ( 0 , 2 , 3 , 4 , 11 )
    GROUP BY p.statusid ,
            ps.status ,
            m.state






GO


