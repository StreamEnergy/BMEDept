USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_EAGLE_FEA_CustomersByProgramCode]    Script Date: 08/26/2014 13:43:38 ******/
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

CREATE VIEW [dbo].[v_EAGLE_FEA_CustomersByProgramCode]
AS
    SELECT  rp.AccountNumber ,
            ra.DesignatedAccountNumber ,
            ra.ProgramCode ,
            rr.ReferredAccountNumber ,
            ROW_NUMBER() OVER ( PARTITION BY rp.AccountNumber ,
                                ra.DesignatedAccountNumber ORDER BY cc.[App Date] ) [NumberCust]
    FROM    EAGLE.dbo.RPDesignatedAccount ra WITH ( NOLOCK )
    INNER JOIN EAGLE.dbo.RPParticipant rp WITH ( NOLOCK ) ON rp.AccountNumber = ra.ParticipantAccountNumber
    INNER JOIN EAGLE.dbo.RPReferredAccount rr WITH ( NOLOCK ) ON rr.DesignatedAccountNumber = ra.DesignatedAccountNumber
    INNER JOIN EAGLE.dbo.tblCustomers cc WITH ( NOLOCK ) ON cc.[Customer Number] = rr.ReferredAccountNumber
    WHERE   rp.AccountStatus = 'Active'
            AND LEFT(rp.AccountNumber , 1) <> 'A'
            AND ra.AccountStatus IN ( 'Active' , 'Pending' , 'PreVerify' )
            AND rr.AccountStatus IN ( 'Active' , 'Pending' , 'PreVerify' )

GO


