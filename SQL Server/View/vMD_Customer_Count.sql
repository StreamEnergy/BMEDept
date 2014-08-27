USE [StreamInternal]
GO

/****** Object:  View [dbo].[vMD_Customer_Count]    Script Date: 08/26/2014 15:16:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
						Preetha Sridhar						Source for Customer_Counter.wf_Get_Count.s_Customer_Count_MD
						& Uma Murala 
						& Eric McCormick
08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/


CREATE VIEW [dbo].[vMD_Customer_Count]
AS
    SELECT  SUM(cust_count) AS MD_COUNT ,
            AS_OF_DATE
    FROM    dbo.v_Customer_Count_Detail
    WHERE   STATE = 'Maryland'
    GROUP BY AS_OF_DATE





GO


