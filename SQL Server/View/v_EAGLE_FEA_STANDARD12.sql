USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_EAGLE_FEA_STANDARD12]    Script Date: 08/26/2014 13:49:18 ******/
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

CREATE VIEW [dbo].[v_EAGLE_FEA_STANDARD12]
AS
    SELECT  DesignatedAccountNumber
    FROM    StreamInternal.dbo.[v_EAGLE_FEA_AccountListing] A
    INNER JOIN EAGLE.dbo.tblConferences con ON con.[IA Number] = A.ParticipantAccountNumber
                                               AND con.Conference = 'Ignition 2014'
    WHERE   AppDate > '09/28/2013'
    GROUP BY DesignatedAccountNumber
    HAVING  COUNT(*) > 11



GO


