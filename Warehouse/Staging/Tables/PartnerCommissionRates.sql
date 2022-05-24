CREATE TABLE [Staging].[PartnerCommissionRates] (
    [PartnerID]      INT           NULL,
    [PartnerName]    VARCHAR (100) NULL,
    [CommissionType] VARCHAR (150) NULL,
    [EPOCU_E]        FLOAT (53)    NULL,
    [EPOCU_P]        FLOAT (53)    NULL,
    [EPOCU_O]        FLOAT (53)    NULL,
    [EPOCU_C]        FLOAT (53)    NULL,
    [EPOCU_U]        FLOAT (53)    NULL,
    [DateAdded]      DATETIME      NULL,
    [CurrentRate]    BIT           NULL
);

