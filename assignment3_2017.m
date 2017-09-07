% ENSC180-Assignment3

% Student Name 1: Kai Sackville-Hii

% Student 1 #: 301310336

% Student 1 userid (email): ksackvil (ksackvil@sfu.ca)

% Student Name 2: James Andrews

% Student 2 #: 301309789

% Student 2 userid (email): jca336 (jca336@sfu.ca)

% Below, edit to list any people who helped you with the assignment, 
%      or put ‘none’ if nobody helped (the two of) you.

% Helpers: NONE

% Instructions:
% * Put your name(s), student number(s), userid(s) in the above section.
% * Edit the "Helpers" line.  
% * Your group name should be "A3_<userid1>_<userid2>" (eg. A3_stu1_stu2)
% * Form a group 
%   as described at:  https://courses.cs.sfu.ca/docs/students
% * You will submit THIS file (assignment3_2017.m),    
%   and your video file (assignment3.avi or possibly similar).
% Craig Scratchley, Spring 2017

function frameArray = assignment3_2017
tic
MAX_FRAMES = 1440; % you can change this and consider increasing it.
RESOLUTION = 512; % you can change this and consider increasing it.
DURATION = 90; % Duration of video -- you can change this if you want.

% Colors
MAX_DEPTH = 200; % you will probably need to increase this.
CMAP=colormap(flipud(colorcube(MAX_DEPTH))); %change the colormap as you want.

WRITE_VIDEO_TO_FILE = true; % change this as you like (true/false)
DO_IN_PARALLEL = true; %change this as you like (true/false)

if DO_IN_PARALLEL
    startClusterIfNeeded
end

if WRITE_VIDEO_TO_FILE
    openVideoFile
end

if DO_IN_PARALLEL || ~WRITE_VIDEO_TO_FILE 
    %preallocate struct array 
    %frameArray=struct('cdata',cell(1,MAX_FRAMES),'colormap',cell(1,MAX_FRAMES));
end

% the path "around" the mandelbrot set, associating centres of frames
%     with zoom (magnification) levels. 

% constant centered point
cen_1 = -0.745428+0.113009i; 
cen_2 = -0.748+0.1i;  
cen_3 = -0.16070135+1.0375665i;
cen_4 = -0.7453-0.1127i;

r1 = 2*pi; %one revolution

%             index centre   zoom      rotation (radians)       
PATH_POINTS =[ 
              0,    0,       0         0;
              %centered at #1
              12.5, cen_1,   0,        0;
              25,   cen_1,   10.414,   0;
              75,   cen_1,   10.414,   r1;
              87.5, cen_1,   8.414,    r1;
              100,  cen_1    10.414,   r1;   
              125,  cen_1,   0,        r1;
              %centered at #2
              137.5,cen_2,   0,        r1;
              150,  cen_2,   6.5713,   r1;
              200,  cen_2,   6.5713,   2*r1;
              212.5,cen_2,   4.5713,   2*r1;
              225,  cen_2,   6.5713,   2*r1;
              250,  cen_2,   0,        2*r1;  
              %centered at #3
              262.5,cen_3,   0,        2*r1;              
              275,  cen_3,   12,       2*r1;
              325,  cen_3,   12,       3*r1;
              337.5,cen_3,   10,       3*r1;
              350,  cen_3,   12,       3*r1;
              375,  cen_3,   0,        3*r1; 
              %centered at #4
              387.5,cen_4,   0,        3*r1;
              400,  cen_4,   7.6009,   3*r1;
              450,  cen_4,   7.6009,   4*r1; 
              462.5,cen_4,   5.9915,   4*r1; 
              475,  cen_4,   7.6009,   4*r1; 
              500,  cen_4,   0,        4*r1]; 

SIZE_0 = 1.5; % the "size" from the centre of a frame with no zooming.

% scale indexes to number of frames.
scaledIndexArray = PATH_POINTS(:, 1).*((MAX_FRAMES-1)/PATH_POINTS(end, 1));

% interpolate centres and zoom levels.
interpArray = interp1(scaledIndexArray, PATH_POINTS(:, 2:end), 0:(MAX_FRAMES-1), 'pchip');

zoomArray = interpArray(:,2); % zoom level of each frame
rotArray = interpArray(:,3);

% ***** modify the below line to consider zoom levels.
sizeArray = SIZE_0 * ones(MAX_FRAMES,1); % size from centre of each frame.

sizeArray = sizeArray .* exp( (-1.*zoomArray));

centreArray = interpArray(:,1);  % centre of each frame

iterateHandle = @iterate;

tic % begin timing
if DO_IN_PARALLEL
    parfor frameNum = 1:MAX_FRAMES
        %evaluate function iterate with handle iterateHandle
        frameArray(frameNum) = feval(iterateHandle, frameNum);
    end
else
    for frameNum = 1:MAX_FRAMES
        if WRITE_VIDEO_TO_FILE
            %frame has already been written in this case
            iterate(frameNum);
        else
            frameArray(frameNum) = iterate(frameNum);
        end
    end
end

if WRITE_VIDEO_TO_FILE
    if DO_IN_PARALLEL
        writeVideo(vidObj, frameArray);
    end
    close(vidObj);
    toc %end timing
else
    toc %end timing
    %clf;
    set(gcf, 'Position', [100, 100, RESOLUTION + 10, RESOLUTION + 10]);
    axis off;
    shg; % bring the figure to the top to be seen.
    movie(gcf, frameArray, 1, MAX_FRAMES/DURATION, [5, 5, 0, 0]);
end

    function frame = iterate (frameNum)

        centreX = real(centreArray(frameNum)); 
        centreY = imag(centreArray(frameNum)); 
        
        size = sizeArray(frameNum); 
        rotate = rotArray(frameNum);
        
        x = linspace(centreX - size, centreX + size, RESOLUTION);
        %you can modify the aspect ratio if you want.
        y = linspace(centreY - size, centreY + size, RESOLUTION);
        
        % the below might work okay unless you want to further optimize
        % Create the two-dimensional complex grid using meshgrid
        [X,Y] = meshgrid(x,y);
        z0 = X + 1i*Y;
        trans = centreX + 1i*centreY;
        R = cos(rotate) + sin(rotate)*1i;
        z0 = (z0- trans)*R + trans;
        
        % Initialize the iterates and counts arrays.
        z = z0;
        
        % needed for mex, assumedly to make z elements separate
        %in memory from z0 elements.
        z(1,1) = z0(1,1); 
        
        % make c of type uint16 (unsigned 16-bit integer)
        c = zeros(RESOLUTION, RESOLUTION, 'uint16');
        
        % Here is the Mandelbrot iteration.
        c(abs(z) < 2) = 1;
        
        % below line turns warning off for MATLAB R2015b and similar
        %   releases of MATLAB.  Those releases have a bug causing a 
        %   warning for mex invocations like ours.  
        % warning( 'off', 'MATLAB:lang:badlyScopedReturnValue' );

        depth = MAX_DEPTH; % you can make depth dynamic if you want.
        
        for k = 2:depth
            [z,c] = mandelbrot_step(z,c,z0,k);
            % mandelbrot_step is a c-mex file that does one step of:
            % z = z.^2 + z0;
            % c(abs(z) < 2) = k;
        end
        
        % create an image from c and then convert to frame.  Use CMAP
        frame = im2frame(ind2rgb(c, CMAP));
        if WRITE_VIDEO_TO_FILE && ~DO_IN_PARALLEL
            writeVideo(vidObj, frame);
        end
        
        %disp(['frame=' num2str(frameNum)]);
    end

    function startClusterIfNeeded
        myCluster = parcluster('local');
        if isempty(myCluster.Jobs) || ~strcmp(myCluster.Jobs(1).State, 'running')
            PHYSICAL_CORES = feature('numCores');
            
            % "hyperthreads" per physical core
            LOGICAL_PER_PHYSICAL = 2; %valid for the i7 on Craig's desktop
            
            % you can change the NUM_WORKERS calculation below if you want.
            NUM_WORKERS = (LOGICAL_PER_PHYSICAL + 1) * PHYSICAL_CORES;
            myCluster.NumWorkers = NUM_WORKERS;
            saveProfile(myCluster);
            disp('This may take a while when needed!')
            parpool(NUM_WORKERS);
        end
    end

    function openVideoFile
        % create video object
        vidObj = VideoWriter('assignment3');
        %vidObj.Quality = 100; % or consider changing
        vidObj.FrameRate = MAX_FRAMES/DURATION;
        open(vidObj);
    end
toc
end

% Look at the mandelbrot_step.c file and compare with the mandelbrot_step.m file. What do you
% think is the primary optimization that file mandelbrot_step.c leverages? [5 points]

% The c-code will not iterate values that have already escaped 2, 
% whereas the .m will continue to iterate every value regardless if it 
% has already escaped.  This means the c-code iterates less as 
% the program runs, but the m file always iterates the same amount 

% Fill in the following comments depending on your focus area(s):
% Area 1: Highlight the artistic and mathematical merit of your video/programming here: 

% For artistic marit, we increased the depth, frame rate, and resolution to
% create a sharper image. As seen in the video, an array of diffrent colors
% can be seen while zooming into the set. We chose four intresting points
% to zoom into, each displaying the complexity and beauty of the Manderbolt
% set. Each point has a diffrent zoom level, giving the viewer four
% diverese zooms into the set. At each point the whole set is rotated 360
% degrees, providing a stunning visual display. The rotation of the set is
% a highlight of the mathimatical merit put into this assignment. To rotate
% the set we used the angle form of a complex number, which is |z|(cos(q)
% +i sin(q)).Multiplying two complex numbers adds their angles and multiplies their magnitudes.
% So multiply an array of complex numbers by a complex number of the form
% cos(q) + i sin(q) will rotate the entire array by q about the origin,
% thus rotationg the whole set.


% Area 2: With the foundational code provided, if you zoom to a certain level of the video,
% the resulting frame image becomes somehow grainy and pixelated. Why does this happen? 
% (Hint: you may need to increase the value of depth to notice the pixilation.)

% If the zoom is in a part of the fringe where selected points to evaluate escape 2 
% after a number of iterations near the value of depth, the points that escape after 
% a few more iterations larger than depth will not display properly.  This could lead 
% to the image becoming grainy.  Another cause could be where the filaments of the mandelbrot 
% set become to thin to accurately display with a resolution that is too small, detracting 
% their finer shape into a coarser one.  These two effects combined could lead to a loss of
% definition at farther zoom levels.

% Area 3 (performance improvement): Report before and after each significant change the 
% execution times and, if applicable, the memory usage of your primary data structures.
% Also provide a description of the circumstances under which the optimization(s) should be useful.

% N/A


