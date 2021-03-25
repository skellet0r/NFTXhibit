from collections import defaultdict


class State:
    def __init__(self):
        # tokens[token] -> childcontracts[childcontract] -> childtokens
        self.tokens = defaultdict(lambda: defaultdict(set))

    def receive_child(self, token_id: int, child_contract: str, child_token: int):
        """Receive a child token."""
        self.tokens[token_id][child_contract].add(child_token)

    def remove_child(self, token_id: int, child_contract: str, child_token: int):
        """Remove a child token."""
        self.tokens[token_id][child_contract].remove(child_token)

    def child_contracts(self, token_id: int):
        """Get all child contracts of a token."""
        return {k for k, v in self.tokens[token_id].items() if len(v) > 0}

    def total_child_contracts(self, token_id: int):
        """Get the total number of child contracts of a token."""
        return len(self.child_contracts(token_id))

    def child_tokens(self, token_id: int, child_contract: str):
        """Get all the child tokens held by a token from a specific contract."""
        return self.tokens[token_id][child_contract]

    def total_child_tokens(self, token_id: int, child_contract: str):
        """Get the total number of child tokens held by a token from a specific contract."""
        return len(self.child_tokens(token_id, child_contract))
