﻿CREATE TABLE [Prototype].[Daz_PreCampaign_Features] (
    [CINID]                   INT           NULL,
    [IronOfferID]             INT           NOT NULL,
    [FanID]                   INT           NOT NULL,
    [GroupName]               VARCHAR (1)   NOT NULL,
    [StartDate]               DATE          NULL,
    [EndDate]                 DATE          NULL,
    [Gender]                  CHAR (1)      NULL,
    [AgeCurrent]              TINYINT       NULL,
    [HeatmapCameoGroup]       VARCHAR (151) NULL,
    [HeatmapScore]            FLOAT (53)    NULL,
    [MinDriveTime]            FLOAT (53)    NULL,
    [MinDriveDist]            FLOAT (53)    NULL,
    [HasDD]                   INT           NULL,
    [HasCC]                   INT           NULL,
    [Sales_1]                 MONEY         NULL,
    [Frequency_1]             INT           NULL,
    [Recency_1]               INT           NULL,
    [MainBrand_Sales_1]       MONEY         NULL,
    [MainBrand_Frequency_1]   INT           NULL,
    [MainBrand_Recency_1]     INT           NULL,
    [Online_Sales_1]          MONEY         NULL,
    [Online_Frequency_1]      INT           NULL,
    [Online_Recency_1]        INT           NULL,
    [CreditCard_Sales_1]      MONEY         NULL,
    [CreditCard_Frequency_1]  INT           NULL,
    [CreditCard_Recency_1]    INT           NULL,
    [Sales_2]                 MONEY         NULL,
    [Frequency_2]             INT           NULL,
    [Recency_2]               INT           NULL,
    [MainBrand_Sales_2]       MONEY         NULL,
    [MainBrand_Frequency_2]   INT           NULL,
    [MainBrand_Recency_2]     INT           NULL,
    [Online_Sales_2]          MONEY         NULL,
    [Online_Frequency_2]      INT           NULL,
    [Online_Recency_2]        INT           NULL,
    [CreditCard_Sales_2]      MONEY         NULL,
    [CreditCard_Frequency_2]  INT           NULL,
    [CreditCard_Recency_2]    INT           NULL,
    [Sales_3]                 MONEY         NULL,
    [Frequency_3]             INT           NULL,
    [Recency_3]               INT           NULL,
    [MainBrand_Sales_3]       MONEY         NULL,
    [MainBrand_Frequency_3]   INT           NULL,
    [MainBrand_Recency_3]     INT           NULL,
    [Online_Sales_3]          MONEY         NULL,
    [Online_Frequency_3]      INT           NULL,
    [Online_Recency_3]        INT           NULL,
    [CreditCard_Sales_3]      MONEY         NULL,
    [CreditCard_Frequency_3]  INT           NULL,
    [CreditCard_Recency_3]    INT           NULL,
    [Sales_4]                 MONEY         NULL,
    [Frequency_4]             INT           NULL,
    [Recency_4]               INT           NULL,
    [MainBrand_Sales_4]       MONEY         NULL,
    [MainBrand_Frequency_4]   INT           NULL,
    [MainBrand_Recency_4]     INT           NULL,
    [Online_Sales_4]          MONEY         NULL,
    [Online_Frequency_4]      INT           NULL,
    [Online_Recency_4]        INT           NULL,
    [CreditCard_Sales_4]      MONEY         NULL,
    [CreditCard_Frequency_4]  INT           NULL,
    [CreditCard_Recency_4]    INT           NULL,
    [Sales_5]                 MONEY         NULL,
    [Frequency_5]             INT           NULL,
    [Recency_5]               INT           NULL,
    [MainBrand_Sales_5]       MONEY         NULL,
    [MainBrand_Frequency_5]   INT           NULL,
    [MainBrand_Recency_5]     INT           NULL,
    [Online_Sales_5]          MONEY         NULL,
    [Online_Frequency_5]      INT           NULL,
    [Online_Recency_5]        INT           NULL,
    [CreditCard_Sales_5]      MONEY         NULL,
    [CreditCard_Frequency_5]  INT           NULL,
    [CreditCard_Recency_5]    INT           NULL,
    [Sales_6]                 MONEY         NULL,
    [Frequency_6]             INT           NULL,
    [Recency_6]               INT           NULL,
    [MainBrand_Sales_6]       MONEY         NULL,
    [MainBrand_Frequency_6]   INT           NULL,
    [MainBrand_Recency_6]     INT           NULL,
    [Online_Sales_6]          MONEY         NULL,
    [Online_Frequency_6]      INT           NULL,
    [Online_Recency_6]        INT           NULL,
    [CreditCard_Sales_6]      MONEY         NULL,
    [CreditCard_Frequency_6]  INT           NULL,
    [CreditCard_Recency_6]    INT           NULL,
    [Sales_13]                MONEY         NULL,
    [Frequency_13]            INT           NULL,
    [Recency_13]              INT           NULL,
    [MainBrand_Sales_13]      MONEY         NULL,
    [MainBrand_Frequency_13]  INT           NULL,
    [MainBrand_Recency_13]    INT           NULL,
    [Online_Sales_13]         MONEY         NULL,
    [Online_Frequency_13]     INT           NULL,
    [Online_Recency_13]       INT           NULL,
    [CreditCard_Sales_13]     MONEY         NULL,
    [CreditCard_Frequency_13] INT           NULL,
    [CreditCard_Recency_13]   INT           NULL,
    [MarketableByEmail]       BIT           NULL,
    [EmailOpenEvents_1Cycle]  INT           NULL,
    [EmailOpenEvents_2Cycle]  INT           NULL,
    [EmailOpenEvents_3Cycle]  INT           NULL,
    [EmailOpenEvents_6Cycle]  INT           NULL,
    [WebLogins_1Cycle]        INT           NULL,
    [WebLogins_2Cycle]        INT           NULL,
    [WebLogins_3Cycle]        INT           NULL,
    [WebLogins_6Cycle]        INT           NULL,
    [CampaignID]              INT           NULL
);


GO
CREATE CLUSTERED INDEX [cix_FanID]
    ON [Prototype].[Daz_PreCampaign_Features]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [nix_FanID__IronOfferID_CampaignID]
    ON [Prototype].[Daz_PreCampaign_Features]([FanID] ASC)
    INCLUDE([IronOfferID], [CampaignID], [GroupName]);

