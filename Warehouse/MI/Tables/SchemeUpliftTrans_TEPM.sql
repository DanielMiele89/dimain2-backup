﻿CREATE TABLE [MI].[SchemeUpliftTrans_TEPM] (
    [FileID]         INT   NOT NULL,
    [RowNum]         INT   NOT NULL,
    [Amount]         MONEY NOT NULL,
    [AddedDate]      DATE  NULL,
    [FanID]          INT   NOT NULL,
    [OutletID]       INT   NOT NULL,
    [PartnerID]      INT   NOT NULL,
    [IsOnline]       BIT   NOT NULL,
    [weekid]         INT   NULL,
    [ExcludeTime]    BIT   NOT NULL,
    [TranDate]       DATE  NOT NULL,
    [IsRetailReport] BIT   NOT NULL
);

