CREATE TABLE [Relational].[BookingCal_Dim_CustomerBase] (
    [CustomerBaseID]          INT           NOT NULL,
    [CustomerBaseDescription] VARCHAR (100) NULL,
    [Weeks]                   INT           NULL,
    CONSTRAINT [pk_CBID] PRIMARY KEY CLUSTERED ([CustomerBaseID] ASC)
);

