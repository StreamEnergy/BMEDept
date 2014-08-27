USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_DPI_Energy]    Script Date: 08/26/2014 13:35:45 ******/
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

/****** Script for SelectTopNRows command from SSMS  ******/
CREATE VIEW [dbo].[v_DPI_Energy]
AS
    SELECT  a.ParticipantAccountNumber ,
            a.DesignatedAccountNumber ,
            b.AccountStatus ,
            COUNT(b.ReferredAccountNumber) AS ReferredAccountCOUNT ,
            a.ProgramCode
    FROM    [Eagle].[dbo].[RPDesignatedAccount] a
    INNER JOIN Eagle.dbo.RPReferredAccount b ON a.ParticipantAccountNumber = b.ParticipantAccountNumber
                                                AND a.DesignatedAccountNumber = b.DesignatedAccountNumber
  --  and a.[ParticipantAccountNumber] = 'A2485250'
    GROUP BY a.ParticipantAccountNumber ,
            b.AccountStatus ,
            a.DesignatedAccountNumber ,
            a.ProgramCode

GO


