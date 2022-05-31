﻿CREATE TABLE [SamW].[First_Second_DDTrans] (
    [BankAccountID] INT          NULL,
    [BrandID]       SMALLINT     NOT NULL,
    [BrandName]     VARCHAR (50) NOT NULL,
    [SectorID]      TINYINT      NULL,
    [SectorName]    VARCHAR (50) NULL,
    [First_Tran]    DATE         NULL,
    [First_Amount]  MONEY        NULL,
    [Second_Tran]   DATE         NULL,
    [Second_Amount] MONEY        NULL,
    [Third_Tran]    DATE         NULL,
    [Third_Amount]  MONEY        NULL
);


GO
CREATE CLUSTERED INDEX [inx_BaID]
    ON [SamW].[First_Second_DDTrans]([BankAccountID] ASC);

