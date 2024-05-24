// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Market_PAR {
    // Participant addresses
    address[] public participants;

    // Last energy balance per participant [Wh]
    mapping (address => int256) public energy_balance;

    // Total production [Wh]
    int256 public total_production = 0;

    // Total consumption [Wh]
    int256 public total_consumption = 0;

    // Ratio between consumption and production
    int256 public ratio = 0;

    // Total number of participants
    int256 public numberOfParticipant = 0;

    // Number of participation during a round
    int256 public numberOfParticipation = 0;

    // Retail prices for buying and selling [$/Wh]
    int256 public retailSellPrice = 100;
    int256 public retailBuyPrice = 70;

    // Retail price upper limit [%]
    int256 public upperRatio = 166;

    // Retail price lower limit [%]
    int256 public lowerRatio = 100;

    // Buying price [$/Wh]
    int256 public buyingPrice = 0;

    // Selling price [$/Wh]
    int256 public sellingPrice = 0;

    // Minimum local selling price (above retail price)
    int256 public minimumLocalSellingPrice = 75;

    // Maximum local buying price (above retail price)
    int256 public maximumLocalBuyingPrice;

    // Bill per participant [$]
    mapping (address => int256) public bill;

    // Pico máximo de demanda [Wh]
    int256 public maxDemand = 0;

    // Total acumulado de demanda [Wh]
    int256 public cumulativeDemand = 0;

    int256 public averageDemand = 0;

    int256 public par = 0;


    /* Events */
    event EnergyPostedEvent(address indexed _target, int256 _value);
    event ParticipantAtClearingRequest(int256 _totParticipant, int256 _nbParticipation);
    event MarketClearedEvent(int256 _sell, int256 _buy, int256 _ratio, int256 _cons, int256 _gen);
    event BillSentEvent(address indexed _target, int256 _value);

    constructor() {
        maximumLocalBuyingPrice = retailSellPrice * 6 / 5;
    }

    // Add a participant to the market
    function addParticipant() public {
        participants.push(msg.sender);
        numberOfParticipant += 1;
        bill[msg.sender] = 0;
        energy_balance[msg.sender] = 0;
    }

    // Remove a participant from the market
    function removeParticipant() public {
        // NOT IMPLEMENTED YET
    }

    // Broadcast energy balance
    function postEnergyBalance(int256 amount) public {
        energy_balance[msg.sender] = amount;
        emit EnergyPostedEvent(msg.sender, amount);

        if (amount < 0) {
            total_production += -1 * amount;
        } else {
            total_consumption += amount;
        }

        numberOfParticipation += 1;

        if (amount > 0) {
            if (amount > maxDemand) {
                maxDemand = amount;
            }
            cumulativeDemand += amount;
        }
    }

    // Clear the market (set the prices and send bills)
    function clearMarket() public {
        // Only trigger the market when everybody has participated
        require(numberOfParticipation >= numberOfParticipant);
        emit ParticipantAtClearingRequest(numberOfParticipant, numberOfParticipation);

        // Reset the market participation
        numberOfParticipation = 0;

        // Calculate the ratio between production and consumption
        if (total_production == 0) {
        // There is no local energy but cannot be 0 so we make it 100 lower than loads
        ratio = 100000;

        } else {
        // Ratio is calulated normally with a factor 100 to avoid floats
        ratio = total_consumption * 100 / total_production;
        }

        // The network need more local production
        if (ratio >= upperRatio) {
        // Local energy is cheap but still producer earn more than retail price
        sellingPrice = minimumLocalSellingPrice;

        // Buying price depends on the portion of local energy
        // Local energy price * ratio + retail price for the remaining energy
        buyingPrice = sellingPrice * 100 / ratio + retailSellPrice - retailSellPrice * 100 / ratio;
        }

        // The network is slowly approaching 100% local production
        // The price of buying local generation goes up
        // this encourage consumption to increase in order to avoid high prices
        if (ratio < upperRatio && ratio > lowerRatio) {
        // Linear equation joining the minimum selling price to the maximum buying price
        int a = (minimumLocalSellingPrice - maximumLocalBuyingPrice) * 100 / (upperRatio - lowerRatio);
        int b = maximumLocalBuyingPrice * 100 - a * lowerRatio;
        sellingPrice = (a * ratio + b) / 100;

        // Buying price depends on the portion of local energy and its price
        // Same equatio as previous section
        buyingPrice = sellingPrice * 100 / ratio + retailSellPrice - retailSellPrice * 100 / ratio;

        // It seems that rounding problem can make buying_price larger?
        if (buyingPrice > maximumLocalBuyingPrice) {
            buyingPrice = maximumLocalBuyingPrice;
        }
        }

        // Local generatio is back feeding to the main grid
        if (ratio <= lowerRatio) {
        // Buying price is at its maximum to encourage more consumption
        // to lower the price
        buyingPrice = maximumLocalBuyingPrice;

        // Selling price progressively decrease as the excess power is sold
        // at a lower retail price
        sellingPrice = buyingPrice * ratio / 100 + retailBuyPrice - retailBuyPrice * ratio / 100;
        }

        // Event marked cleared
        emit MarketClearedEvent(sellingPrice, buyingPrice, ratio, total_consumption, total_production);

        // Reset total production and total consumption for this round
        total_consumption = 0;
        total_production = 0;

        // Send a bill to all the participants
        _billAllParticipants();

        // Calcular la demanda promedio
        averageDemand = numberOfParticipant > 0 ? int256(cumulativeDemand) / int256(numberOfParticipant) : int256(0);

        // Calcular el PAR
        par = averageDemand > 0 ? int256(maxDemand) * 100 / averageDemand : int256(0);

        maxDemand = 0;
        cumulativeDemand = 0;
    }

    function _billAllParticipants() internal {
        // Loop over all the participants
        for (uint256 i = 0; i < participants.length; i++) {
            // Bill participant differently if they are prosumers or consumers
            if (energy_balance[participants[i]] > 0) {
                int256 positiveBill = buyingPrice * energy_balance[participants[i]];
                bill[participants[i]] += positiveBill;
                emit BillSentEvent(participants[i], positiveBill);
            } else {
                int256 negativeBill = sellingPrice * energy_balance[participants[i]];
                bill[participants[i]] += negativeBill;
                emit BillSentEvent(participants[i], negativeBill);
            }
        }
    }

    // End of the contract
}
