USE [StreamInternal]
GO

/****** Object:  View [dbo].[vPA_Customer_Count]    Script Date: 08/26/2014 15:17:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
						Preetha Sridhar						Source for Customer_Counter.wf_Get_Count.s_Customer_Count_PA
						& Uma Murala						History:			03.11:  Created.
						& Eric McCormick
08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/

CREATE VIEW [dbo].[vPA_Customer_Count]
AS
    -- this is the count for active/on-flow and enrollment accepted customers only
SELECT  SUM(cust_count) AS PA_COUNT ,
        AS_OF_DATE
FROM    dbo.v_Customer_Count_Detail
WHERE   STATE = 'Pennsylvania'
GROUP BY AS_OF_DATE






GO


