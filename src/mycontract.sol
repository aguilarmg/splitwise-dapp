pragma solidity ^0.6.6;

/*
 * @title Splitwise
 * @author miguelaguilar.eth
 * @dev Implement the Splitwise application in a decentralised manner.
 */
contract Splitwise {
    // Keep track of who a debtor owes money to and the amount of owed to each creditor.
    mapping(address => mapping(address => uint32)) debts;

    /*
     * @dev Return the amount of money that _debtor owes _creditor.
     * @param
     */
    function lookup(address _debtor, address _creditor)
        public
        view
        returns (uint32 ret)
    {
        return debts[_debtor][_creditor];
    }

    /*
     * @dev
     * @param _creditor: address of the person who msg.sender owes _amount to.
     * @param _amount: amount that msg.sender owes _creditor for.
     * @param _path: array of addresses that forms a cycle from _creditor to msg.sender in the
     * graph of debts.
     * @param _minDebt: uint32 representing the minimum debt found in the path from _creditor to
     * msg.sender.
     */
    function add_IOU(
        address _creditor,
        uint32 _amount,
        address[] memory _path,
        uint32 _minDebt
    ) public {
        // Require that the amount that is owed to _creditor be positive.
        require(_amount >= 0, "Amount to owe must be positive.");
        // Require that a person cannot add an IOU to themselves.
        require(_creditor != msg.sender, "You cannot add an IOU to yourself.");
        
        // Add to the amount that msg.sender owes to _creditor.
        debts[msg.sender][_creditor] += _amount;
        
        if (_path.length > 0) {
            // Resolve any cycles that might have occurred.
            _resolveCycles(msg.sender, _creditor, _path, _minDebt);   
        }
    }

    /*
     * @dev Iterates through the _path of debts from _creditor to _debtor and deducts the amount
     * miniimum debt in the cycle from each edge along the path.
     * @param _debtor: address of the _debtor.
     * @param _creditor: address of the _creditor.
     * @param _path: array of addresses that forms a cycle in the graph of debts.
     * @param _minDebt: uint32 representing the minimum debt found in the path from _creditor to
     * msg.sender.
     */
    function _resolveCycles(
        address _debtor,
        address _creditor,
        address[] memory _path,
        uint32 _minDebt
    ) private {
        // For a path to be valid, it must start with the _creditor and end with the _debtor.
        require(
            _path[0] == _creditor && _path[_path.length - 1] == _debtor,
            "This path is invalid."
        );
        // Assume that the cycle is less than 10 edges in length.
        require(_path.length < 10);
        // Decrement the debts owed by an amount of _minDebt.
        for (uint16 i = 0; i < _path.length - 1; i++) {
            // Require that every edge in the cycle is greater than or equal to the presumed
            // _minDebt along the cycle.
            require(lookup(_path[i], _path[i+1]) >= _minDebt, "minDebt was not valid.");
            debts[_path[i]][_path[i + 1]] -= _minDebt;
        }
        
        // Close the loop from creditor to debtor.
        debts[_debtor][_creditor] -= _minDebt;
    }
}
