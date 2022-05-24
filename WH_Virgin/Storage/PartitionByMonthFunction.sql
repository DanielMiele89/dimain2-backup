﻿CREATE PARTITION FUNCTION [PartitionByMonthFunction](DATETIME2 (0))
    AS RANGE RIGHT
    FOR VALUES ('01/01/2019 00:00:00', '02/01/2019 00:00:00', '03/01/2019 00:00:00', '04/01/2019 00:00:00', '05/01/2019 00:00:00', '06/01/2019 00:00:00', '07/01/2019 00:00:00', '08/01/2019 00:00:00', '09/01/2019 00:00:00', '10/01/2019 00:00:00', '11/01/2019 00:00:00', '12/01/2019 00:00:00', '01/01/2020 00:00:00', '02/01/2020 00:00:00', '03/01/2020 00:00:00', '04/01/2020 00:00:00', '05/01/2020 00:00:00', '06/01/2020 00:00:00', '07/01/2020 00:00:00', '08/01/2020 00:00:00', '09/01/2020 00:00:00', '10/01/2020 00:00:00', '11/01/2020 00:00:00', '12/01/2020 00:00:00', '01/01/2021 00:00:00', '02/01/2021 00:00:00', '03/01/2021 00:00:00', '04/01/2021 00:00:00', '05/01/2021 00:00:00', '06/01/2021 00:00:00', '07/01/2021 00:00:00', '08/01/2021 00:00:00', '09/01/2021 00:00:00', '10/01/2021 00:00:00', '11/01/2021 00:00:00', '12/01/2021 00:00:00', '01/01/2022 00:00:00', '02/01/2022 00:00:00', '03/01/2022 00:00:00', '04/01/2022 00:00:00', '05/01/2022 00:00:00', '06/01/2022 00:00:00');

