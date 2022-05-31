CREATE TABLE [PatrickM].[breakagesegments] (
    [rundate]              DATE         NULL,
    [CustomerSegment]      VARCHAR (15) NULL,
    [SubSegment]           VARCHAR (31) NULL,
    [vol]                  INT          NULL,
    [BPReductions]         MONEY        NULL,
    [MerchantReductions]   MONEY        NULL,
    [BankFundedReductions] MONEY        NULL,
    [BreakageReductions]   MONEY        NULL,
    [OtherReductions]      MONEY        NULL,
    [BPEarnings]           MONEY        NULL,
    [MerchantEarnings]     MONEY        NULL,
    [BankFundedEarnings]   MONEY        NULL,
    [BreakageEarnings]     MONEY        NULL,
    [OtherEarnings]        MONEY        NULL
);

