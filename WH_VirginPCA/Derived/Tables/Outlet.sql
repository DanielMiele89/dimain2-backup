CREATE TABLE [Derived].[Outlet] (
    [PartnerID]       INT            NOT NULL,
    [OutletID]        INT            NOT NULL,
    [MerchantID]      NVARCHAR (50)  NOT NULL,
    [ChannelID]       INT            NULL,
    [Channel]         VARCHAR (10)   NULL,
    [OutletReference] VARCHAR (20)   NULL,
    [Address1]        NVARCHAR (100) NULL,
    [Address2]        NVARCHAR (100) NULL,
    [City]            NVARCHAR (100) NULL,
    [PostCode]        NVARCHAR (20)  NULL,
    [PostalSector]    VARCHAR (6)    NULL,
    [PostArea]        VARCHAR (2)    NULL,
    [Region]          VARCHAR (30)   NULL,
    [Latitude]        VARCHAR (25)   NULL,
    [Longitude]       VARCHAR (25)   NULL,
    CONSTRAINT [pk_OutletID] PRIMARY KEY CLUSTERED ([OutletID] ASC) WITH (FILLFACTOR = 80)
);




GO
GRANT SELECT
    ON OBJECT::[Derived].[Outlet] TO [visa_etl_user]
    AS [New_DataOps];

