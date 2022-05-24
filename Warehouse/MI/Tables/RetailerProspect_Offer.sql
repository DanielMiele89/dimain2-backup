CREATE TABLE [MI].[RetailerProspect_Offer] (
    [ID]             TINYINT        IDENTITY (1, 1) NOT NULL,
    [OfferName]      VARCHAR (50)   NOT NULL,
    [IsCore]         BIT            NOT NULL,
    [IsRBS]          BIT            NOT NULL,
    [Uplift]         DECIMAL (5, 4) NOT NULL,
    [CommissionRate] DECIMAL (5, 4) NOT NULL,
    CONSTRAINT [PK_MI_RetailerProspect_Offer] PRIMARY KEY CLUSTERED ([ID] ASC)
);

