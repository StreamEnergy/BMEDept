USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_EAGLE_FEA_HWY2FDM25]    Script Date: 08/26/2014 13:44:10 ******/
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

CREATE VIEW [dbo].[v_EAGLE_FEA_HWY2FDM25]
AS
    SELECT  DesignatedAccountNumber
    FROM    StreamInternal.dbo.[v_EAGLE_FEA_AccountListing] A
    WHERE   AppDate > '09/28/2013'
    GROUP BY DesignatedAccountNumber
    HAVING  COUNT(*) > 4
            AND COUNT(*) < 10



GO


