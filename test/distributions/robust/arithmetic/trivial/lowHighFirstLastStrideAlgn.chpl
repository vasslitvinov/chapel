use driver_domains;

writeln("--- low ---");
writeln(Dom1D.low);
writeln(Dom2D.low);
writeln(Dom3D.low);
writeln(Dom4D.low);
writeln(Dom2D32.low);

writeln("--- high ---");
writeln(Dom1D.high);
writeln(Dom2D.high);
writeln(Dom3D.high);
writeln(Dom4D.high);
writeln(Dom2D32.high);

writeln("--- alignedLow ---");
writeln(Dom1D.alignedLow);
writeln(Dom2D.alignedLow);
writeln(Dom3D.alignedLow);
writeln(Dom4D.alignedLow);
writeln(Dom2D32.alignedLow);

writeln("--- alignedHigh ---");
writeln(Dom1D.alignedHigh);
writeln(Dom2D.alignedHigh);
writeln(Dom3D.alignedHigh);
writeln(Dom4D.alignedHigh);
writeln(Dom2D32.alignedHigh);

writeln("--- first ---");
writeln(Dom1D.first);
writeln(Dom2D.first);
writeln(Dom3D.first);
writeln(Dom4D.first);
writeln(Dom2D32.first);

writeln("--- last ---");
writeln(Dom1D.last);
writeln(Dom2D.last);
writeln(Dom3D.last);
writeln(Dom4D.last);
writeln(Dom2D32.last);

writeln("--- stride ---");
writeln(Dom1D.stride);
writeln(Dom2D.stride);
writeln(Dom3D.stride);
writeln(Dom4D.stride);
writeln(Dom2D32.stride);

writeln("--- alignment ---");
// The domains Dom1D et al. are not stridable, so have ambiguous alignment.
// Instead we print the (well-defined) alignment after applying 'by'.
writeln((Dom1D by 2).alignment);
writeln((Dom2D by 2).alignment);
writeln((Dom3D by 2).alignment);
writeln((Dom4D by 2).alignment);
writeln((Dom2D32 by 2:int(32)).alignment);
