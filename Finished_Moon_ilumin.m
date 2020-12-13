%%Working example
 
%%Our DSK file
%%moon_test.bds

            
main_dir='C:\Users\skate\Dropbox (CSU Fullerton)\Matlab Code\M370_Project';
addpath([main_dir '\mice\src\mice']); % MATLAB wrap around C files
addpath([main_dir '\mice\lib']);  % interface between MATLAB and C programs 
addpath([main_dir '\myScripts']); % your matlab functions
kernel_dir=[main_dir '\Kernels']; % where you store all trajectory kernels

work_dir=pwd; % your current directory

cd(kernel_dir);

cspice_furnsh( 'de421.bsp')
% Summary for: de421.bsp 
%   
% Bodies: MERCURY BARYCENTER (1)  SATURN BARYCENTER (6)   MERCURY (199) 
%         VENUS BARYCENTER (2)    URANUS BARYCENTER (7)   VENUS (299) 
%         EARTH BARYCENTER (3)    NEPTUNE BARYCENTER (8)  MOON (301) 
%         MARS BARYCENTER (4)     PLUTO BARYCENTER (9)    EARTH (399) 
%         JUPITER BARYCENTER (5)  SUN (10)                MARS (499) 
%         Start of Interval (ET)              End of Interval (ET) 
%         -----------------------------       ----------------------------- 
%         1899 JUL 29 00:00:00.000            2053 OCT 09 00:00:00.000 
cspice_furnsh('naif0009.tls')%Load leap second file
cspice_furnsh('pck00010.tpc')
cspice_furnsh('SEL_M_071020_090610_SGMH_02.BSP')%Ephemeris data for selene
% Summary for: SEL_M_071020_090610_SGMH_02.BSP 
%   
% Body: KAGUYA (-131) 
%       Start of Interval (ET)              End of Interval (ET) 
%       -----------------------------       ----------------------------- 
%       2007 OCT 20 02:31:05.182            2007 DEC 11 02:31:05.183 
%       2007 DEC 11 16:16:05.183            2008 FEB 04 20:31:05.184 
%       2008 FEB 05 04:16:05.184            2008 MAR 29 16:31:05.185 
%       2008 MAR 30 00:16:05.185            2008 MAY 24 15:01:05.185 
%       2008 MAY 24 20:44:05.185            2008 JUL 16 07:31:05.183 
%       2008 JUL 16 15:31:05.183            2008 SEP 10 05:31:05.182 
%       2008 SEP 10 13:31:05.182            2008 NOV 03 00:31:05.182 
%       2008 NOV 03 09:01:05.182            2008 DEC 26 21:01:05.183 
%       2008 DEC 27 05:31:05.183            2009 JAN 01 04:01:05.183 
%       2009 JAN 01 04:01:06.183            2009 FEB 20 20:01:06.185 
%       2009 FEB 20 23:46:06.185            2009 MAR 19 18:01:06.185 
%       2009 MAR 19 22:01:06.185            2009 APR 16 19:01:06.185 
%       2009 APR 16 21:31:06.185            2009 JUN 10 19:31:06.184 

cspice_furnsh('moon_test.bds')
cd(work_dir);
 

% Convert the UTC request time string to seconds past
% J2000 TDB.
%
%We will observe the first instance of Kaguya's ephemeris data
utc = '2007 OCT 20 02:31:05.182 UTC';
%Convert our time into space time(et)     
et = cspice_str2et( utc );
      
%
% Assign observer and target names.
%
% Also set the target body-fixed frame and
% the aberration correction flag.
%
      
target = 'MOON';
obsrvr = 'KAGUYA';  %Current observer
fixref = 'IAU_MOON';   
abcorr= 'LT+S';                
      
ilumth  = {'Ellipsoid', 'DSK/Unprioritized' };  %We'll try both methods
submth =  {'Near Point/Ellipsoid', 'DSK/Nadir/Unprioritized' };
      
for i=1:numel(ilumth)
      
%
% Find the sub-solar point on the Earth as seen from
% Kaguya spacecraft at et. Use the 'near point'
% style of sub-point definition.
               
[ssolpt, trgepc, srfvec] = ...
                        cspice_subslr( submth(i), ...
                        target, et, fixref,  ...
                        abcorr, obsrvr );
      
%
% Now find the sub-spacecraft point on the moon
%
               
[sscpt, trgepc, srfvec] = ...
                       cspice_subpnt( submth(i), ...
                       target, et, fixref, ...
                       abcorr, obsrvr );
      
%
% Find the phase, solar incidence, and emission
% angles at the sub-solar point on the Earth as seen
% from Kaguya at time et.
%
[ trgepc, srfvec, sslphs, sslsol, sslemi ] = ...
                                cspice_ilumin( ilumth(i),   ...
                                target, et,  fixref, ...
                                abcorr, obsrvr, ssolpt );
      
%
% Do the same for the sub-spacecraft point.
%
[ trgepc, srfvec, sscphs, sscsol, sscemi ] = ...
                                cspice_ilumin( ilumth(i), ...
                                target, et, fixref, ...
                                abcorr, obsrvr, sscpt );
      
%
% Convert the angles to degrees and write them out.
%
sslphs = sslphs * cspice_dpr;
sslsol = sslsol * cspice_dpr;
sslemi = sslemi * cspice_dpr;
sscphs = sscphs * cspice_dpr;
sscsol = sscsol * cspice_dpr;
sscemi = sscemi * cspice_dpr;
      
fprintf( [ '\n'                                         ...
           '   cspice_ilumin method: %s\n'                 ...
           '   cspice_subpnt method: %s\n'                 ...
           '   cspice_subslr method: %s\n'                 ...
           '\n'                                            ...
           '      Illumination angles at the '             ...
           'sub-solar point:\n'                            ...
           '\n'                                            ...
           '      Phase angle            (deg): %15.9f\n'  ...
           '      Solar incidence angle  (deg): %15.9f\n'  ...
           '      Emission angle         (deg): %15.9f\n'],...
           char(ilumth(i)),   ...
           char(submth(i)),   ...
           char(submth(i)),   ...
           sslphs,      ...
           sslsol,      ...
           sslemi                                    );
      
if ( i == 0 )
      
fprintf( [ '        The solar incidence angle ' ...
                             'should be 0.\n'                     ...
                             '        The emission and phase '    ...
                             'angles should be equal.\n' ] );
end
      
fprintf( [ '\n'                                            ...
                          '      Illumination angles at the '             ...
                          'sub-s/c point:\n'                              ...
                          '\n'                                            ...
                          '      Phase angle            (deg): %15.9f\n'  ...
                          '      Solar incidence angle  (deg): %15.9f\n'  ...
                          '      Emission angle         (deg): %15.9f\n'],...
                          sscphs, ...
                          sscsol, ...
                          sscemi                                    );
      
               if ( i == 0 )
      
                 fprintf( [ '        The emission angle '  ...
                            'should be 0.\n'               ...
                            '        The solar incidence ' ...
                            'and phase angles should be equal.\n' ] );
                end
      
                 fprintf ( '\n' );
end
      
            %
            % It's always good form to unload kernels after use,
            % particularly in Matlab due to data persistence.
            %
            cspice_kclear