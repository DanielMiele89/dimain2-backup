CREATE TABLE [Prototype].[OutletMatcher] (
    [ID]             INT          IDENTITY (1, 1) NOT NULL,
    [RetailOutletID] INT          NULL,
    [PartnerID]      INT          NULL,
    [MerchantID]     VARCHAR (50) NULL,
    [MatcherID]      INT          NULL,
    [OutletStatusID] INT          NULL,
    [StartDate]      DATE         NULL,
    [EndDate]        DATE         NULL
);

