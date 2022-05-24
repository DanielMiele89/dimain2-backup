﻿CREATE TABLE [Staging].[EPOCU_Assessment_Transactions_CT] (
    [FileID]     INT   NOT NULL,
    [RowNum]     INT   NOT NULL,
    [TranDate]   DATE  NULL,
    [CINID]      INT   NULL,
    [BrandMIDID] INT   NOT NULL,
    [Amount]     MONEY NOT NULL
);

