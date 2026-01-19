# track user contributions per project to ensure it doesn't exceed the allowed 2% of amount to raise by project


# test vectors for contribution function/contract:
# is contribution contract set?
# is contribution contract actually a contract address?
# does raise that user is trying to contribute to exist?
# is the amount greater than 0?
# is the amount equal to mgs.value sent?
# is amount more than or equal to the minimum allowed contribution to any raisebox raise
# is raise currently taking contributions?
# is raise creator trying to self-contribute?
# is user trying to contribute above the max allowed of 20&* of raiseTarget?
# has raiseDeadline been exceeded? deadline is exceeded if current timestamp is greater than creation timestamp + raise duration
# is contributed event emitted on successful contribution
# can user contribute allowed amount at excatly raise deadline
# can user contribute above allowed amount at deadline?
# can user contribute multiple times as long as amount contributed so far hasn't exceeded max allowed per user per project?





# voting should happen after the set time for voting to start have been exceeded, 3 minutes for testing