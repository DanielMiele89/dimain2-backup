CREATE TABLE [APW].[PrePay_Partner] (
    [PartnerID]        INT  NOT NULL,
    [RetailerID]       INT  NOT NULL,
    [BalanceStartDate] DATE NOT NULL,
    PRIMARY KEY CLUSTERED ([PartnerID] ASC)
);

