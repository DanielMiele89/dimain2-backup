CREATE TABLE [APW].[DirectLoad_IronOfferSpendStretch] (
    [IronOfferID]        INT   NOT NULL,
    [SpendStretchAmount] MONEY NOT NULL,
    CONSTRAINT [PK_APW_DirectLoad_IronOfferSpendStretch] PRIMARY KEY CLUSTERED ([IronOfferID] ASC)
);

