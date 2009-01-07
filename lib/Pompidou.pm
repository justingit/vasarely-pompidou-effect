package Pompidou;
use GD; 


use Mouse;
#my $self->threshold = 400;

has 'image'       => (isa => 'Str', is => 'rw', required => 1);
has 'width'       => (isa => 'Int', is => 'rw', required => 0, default => 640);
has 'height'      => (isa => 'Int', is => 'rw', required => 0, default => 800);
has 'heaviness'   => (isa => 'Int', is => 'rw', required => 0, default => 1);

has 'direction'   => (isa => 'Str', is => 'rw', required => 0, default => 'vert');



#has 'column_size' => (isa => 'Int', is => 'rw', required => 0, default => 20);

has 'num_columns' => (isa => 'Int', is => 'rw', required => 0, default => 32);


has 'gutter'      => (isa => 'Int', is => 'rw', required => 0, default => 1);
has 'threshold'   => (isa => 'Int', is => 'rw', required => 0, default => 200);


has 'dark_color'   => (isa => 'Str', is => 'rw', required => 0, default => '0,0,255');
has 'light_color'  => (isa => 'Str', is => 'rw', required => 0, default => '255,0,0');



has 'max_width'   =>  (isa => 'Int', is => 'rw', required => 0, default => 640);
has 'max_height'  =>  (isa => 'Int', is => 'rw', required => 0, default => 800);


sub gimme_img { 
	my $self = shift; 

	return GD::Image->new($self->image); 
}




sub resize { 

	my $self = shift; 
	my $img  = shift;
	
 
	
	my $change_w = ($img->width/$self->max_width);
	my $change_h = ($img->height/$self->max_height);
	my $change_with = 1; 
	if($change_w > $change_h){ 
		$change_with = $change_w; 
	}
	else { 
		$change_with = $change_h; 
	}
	
	my $new_width   =  $img->width / $change_with;
	my $new_height  =  $img->height / $change_with; 
	

	my $new_img = GD::Image->new($new_width, $new_height); 
	   $new_img->copyResampled($img, 0,0, 0,0, $new_width, $new_height, $img->width,$img->height);

	return $new_img; 
	 
	
	
	
}

sub transform { 
	
	my $self = shift; 	
	
	
	my $orig_img = $self->gimme_img; 
	
	$orig_img = $self->resize($orig_img); 
	
	if($self->direction eq 'hor'){ 
		$orig_img = $orig_img->copyRotate90()
	}
	
	
	
	
	my $flip = 0; 
	
	my $checks_out = 0; 
	while($checks_out == 0){ 
		if($orig_img->width % $self->num_columns == 0){ 
			$checks_out = 1; 
		}
		else { 
			$self->num_columns($self->num_columns - 1); 
		}
		if($self->num_columns == 0){ 
			$checks_out = 1; 
		}	
	}
	my $column_size = $orig_img->width / $self->num_columns; 
	
	#my $num_parts  = $orig_img->width / ($self->column_size/2);
	
	my $t_w = $orig_img->width; 
	my $t_h = $orig_img->height; 



	my $transformed = GD::Image->new( $t_w, $t_h );

	

	my $i = 1;
	for ( $i = 1 ; $i <= ($self->num_columns * 2); $i++ ) {

		my $w = ($column_size/2); 
		my $h = $self->height;
	    my $cropped_img = GD::Image->new($w , $h );

	    #print 'Copying from source image: 0,0, '
	    #  . ( ( $chunk_size * $i ) - $chunk_size ) . ",0, "
	    #  . $chunk_size . ','
	    #  . $img->height . ",\n";

	    $cropped_img->copy(

	        $orig_img,

	        0,
	        0,

	        ( ($column_size/2) * $i ) - ($column_size/2),
	        0,

	        ($column_size/2),
	        $self->height
	    );

	    if ( $flip == 0 ) {
	        $cropped_img = $cropped_img->copyFlipHorizontal();
	    }

	    my $transformed_part = $self->transform_col($cropped_img);

	    if ( $flip == 0 ) {
	        $transformed_part = $transformed_part->copyFlipHorizontal();
	        $flip             = 1;
	    }
	    else {
	        $flip = 0;
	    }

	    $transformed->copy(

	        $transformed_part,

	        ( ($column_size/2) * $i ) - ($column_size/2),
	        0,

	        0,
	        0,

	        ($column_size/2),
	        $self->height,

	    );

	}


	if($self->direction eq 'hor'){ 
		$transformed = $transformed->copyRotate270()
	}
	
	
	return $transformed; 



}


sub transform_col {

	my $self     = shift; 
    my $orig_img = shift;
    my $width    = $orig_img->width;
    my $height   = $orig_img->height;

    my $c_pos = -1;

    my @pos = ();

    my $y = 0;
    for ( $y = 0 ; $y < $height ; $y++ ) {
        my $x = 0;
      ROW: for ( $x = 0 ; $x < $width ; $x++ ) {

            my $index = $orig_img->getPixel( $x, $y );
            my ( $r, $g, $b ) = $orig_img->rgb($index);

            # If it's zero, I always want it to be black.
            if ( $c_pos == -1 ) {
                # This doesn't seem to do much: 
				$c_pos = ($self->gutter - 1);
				# /This doesn't seem to do much: 
               	last ROW;
            	
			}

            if ( $x < $c_pos ) {
               
				if(($r+$g+$b) > $self->threshold){ 
					 #print q{ ($r+$g+$b) } . ($r+$g+$b) . "\n";
				#if ( $r == 255 ) {
                    $c_pos = $c_pos - $self->heaviness;

                    last ROW;
                }
            }
            elsif ( $c_pos == $x ) {
				 
                if(($r+$g+$b) > $self->threshold){ 
	#print q{ ($r+$g+$b) } . ($r+$g+$b) . "\n";
				#if ( $r == 255 ) {    #white?
                    $c_pos = $c_pos - $self->heaviness;
                    #if ( $c_pos < 0 ) {
                    #    $c_pos = 0;
                    #}
                    last ROW;
                }
 				elsif ( ($r+$g+$b) < $self->threshold ) {    #black?
               # elsif ( $r == 0 ) {    #black?
				 #print q{ ($r+$g+$b) } . ($r+$g+$b) . "\n";
                    # I kinda just want to lookahead
					if ( $x == ($width-1) - ($self->gutter) ) {
                #    if ( $x == ($width-1) - ($self->gutter - 1) ) {
						$c_pos = $x;
                        last ROW;
                    }
                    else {

                        my $next_pixel_index =
                          $orig_img->getPixel( $x + 1, $y );
                        my ( $r_n, $g_n, $b_n ) =
                          $orig_img->rgb($next_pixel_index);

                        if ( ($r_n+$g_n+$b_n) < $self->threshold) {
                           #? $c_pos = $c_pos + $self->heaviness;
							$c_pos = $x + $self->heaviness;
                           # $c_pos   = $x; 
							last ROW;
                        }
                        else {
                            $c_pos = $x;
                            last ROW;
                        }
                    }
                }

            }

        }

					#<=
        if ( $c_pos < ($self->gutter - 1) ) {
           $c_pos = ($self->gutter - 1); #?
			
        }

        if ( $c_pos >= $width - 1) {
        	$c_pos = ($width - 1) - $self->gutter;
			#die $c_pos; 
			#	$c_pos = $width - 1; 
		}



        push ( @pos, $c_pos );

    }

    my $trans_img = GD::Image->new( $width, $height );

    my $red = $trans_img->colorAllocate( 255, 0, 0 );

    $trans_img->transparent($red);
    $trans_img->interlaced('true');

	my ($w_r, $w_b, $w_g) = split(',', $self->light_color, 3);
    my $white = $trans_img->colorAllocate( $w_r, $w_b, $w_g );

	my ($b_r, $b_b, $b_g) = split(',', $self->dark_color, 3);

	
    my $black = $trans_img->colorAllocate( $b_r, $b_b, $b_g );

    $y     = 0;
    for ( $y = 0 ; $y < $height ; $y++ ) {
        my $x = 0;
        for ( $x = 0 ; $x < $width ; $x++ ) {

            if ( $x <= $pos[$y] ) {
                $trans_img->setPixel( $x, $y, $black );
            }
            else {
                $trans_img->setPixel( $x, $y, $white );
            }
        }
    }
    return $trans_img;

}


1;