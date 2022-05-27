﻿CREATE TABLE [MI].[RetailerReportWeekly_OLD] (
    [ID]                          INT          IDENTITY (1, 1) NOT NULL,
    [WeekID]                      INT          NOT NULL,
    [MonthID]                     INT          NOT NULL,
    [LabelID]                     SMALLINT     NOT NULL,
    [PartnerID]                   INT          NULL,
    [PartnerGroupID]              INT          NULL,
    [ActivatedCardholders]        INT          NOT NULL,
    [NewActivatedCardholders]     INT          NOT NULL,
    [DeactivatedCustomersInMonth] INT          NOT NULL,
    [ActivatedSales]              MONEY        NOT NULL,
    [PostActivatedSales]          MONEY        NOT NULL,
    [PreActivationSales]          MONEY        NOT NULL,
    [ActivatedTrans]              INT          NOT NULL,
    [PostActivatedTrans]          INT          NOT NULL,
    [ActivatedSpender]            INT          NOT NULL,
    [ActivatedCommission]         MONEY        NOT NULL,
    [ControlCardholder]           INT          NOT NULL,
    [ControlSales]                MONEY        NOT NULL,
    [ControlTrans]                INT          NOT NULL,
    [ControlSpender]              INT          NOT NULL,
    [Label]                       VARCHAR (50) NOT NULL,
    [IronOfferID]                 INT          NULL,
    [ClientServicesRef]           VARCHAR (50) NULL
);
