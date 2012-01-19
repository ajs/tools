#!/usr/bin/perl
#

while(<>) {
   if (/^\s*M(\d+)\s+C(\d+)\s+C(\d+)\s+(\d+)/) {
      my($machine,$in,$out,$cost) = ($1,$2,$3,$4);
      # "$cost" is redundant, here, but used to clarify that we're
      # explicitly testing the string-to-number-to-string round-trip.
      # We're told that input costs will be "integers" without
      # clarification. We'll assume for the moment that they'll
      # fit into a double, which is what Perl uses.
      if ("$cost" ne ($cost+0)) {
         die "Numeric overflow or related error dealing with cost '$cost'";
      }
      if ($done_machine[$machine]++) {
         warn "Ignoring duplicate machine $machine";
      } else {
         $nodes{$in}++;
         $nodes{$out}++;
         push @edges, [$in,$out,$cost,$machine];
      }
   } elsif (/\S/) {
      warn "Invalid input line:\n\t$_";
   }
}

@nodes = keys %nodes;
# Sanity check: we expect nodes (chemicals) 1-n without gaps
for($i=1;$i<=@nodes;$i++) {
   unless($nodes{$i}) {
      warn "Sparse list of chemicals is missing $i\n";
   }
}

# So, this is obviously a graphing problem, as it has nodes (chemicals)
# paths between those nodes (machines) and a cost for each path (costs).
# I did some scrounging because I'm horribly out of shape when it comes
# to graph theory, and re-discovered Prim's algorithm, which neatly
# solves this problem with no modifications... kind of disapointing, really

# Prim's algorithm
@Vnew = ($nodes[0]);
@Enew = ();
while(@nodes != @Vnew) {
   foreach 
