%%Working example
 
%%Our DSK file
%%'mars_m129_mol_v01.bds'
%%found under EXOMARS2016/kernels/dsk
            
main_dir='C:\Users\skate\Dropbox (CSU Fullerton)\Matlab Code\M370_Project';
addpath([main_dir '\mice\src\mice']); % MATLAB wrap around C files
addpath([main_dir '\mice\lib']);  % interface between MATLAB and C programs 
addpath([main_dir '\myScripts']); % your matlab functions
kernel_dir=[main_dir '\Kernels']; % where you store all trajectory kernels

work_dir=pwd; % your current directory
cd(kernel_dir); % go into your kernel folder to extract trajectories

cspice_furnsh( 'de430.bsp')%Planet ephemeris data
cspice_furnsh('pck00010.tpc')
cspice_furnsh('mar097.bsp')%Mars ephemeris data
cspice_furnsh('naif0011.tls')%load leap second file
cspice_furnsh('mgs_ext12_ipng_mgs95j.bsp')%mars global surveyor
cspice_furnsh('mars_m129_mol_v01.bds')%DSK
% Convert the UTC request time string to seconds past
% J2000 TDB.
utc = '2003 OCT 13 06:00:00 UTC';
et = cspice_str2et( utc );
  
% Assign observer and target names. The acronym MGS
% indicates Mars Global Surveyor. See NAIF_IDS for a
% list of names recognized by SPICE.
%
% Also set the target body-fixed frame and
% the aberration correction flag.
      
target = 'Mars';    %Assign target name
obsrvr = 'MGS';     %Assign observer name
fixref = 'IAU_MARS';
abcorr = 'CN+S';
      
ilumth  = {'Ellipsoid', 'DSK/Unprioritized' };
submth =  {'Near Point/Ellipsoid', 'DSK/Nadir/Unprioritized' };
      
            for i=1:numel(ilumth)
      
               %
               % Find the sub-solar point on the Earth as seen from
               % the MGS spacecraft at et. Use the 'near point'
               % style of sub-point definition.
               %
               
               [ssolpt, trgepc, srfvec] = ...
                                        cspice_subslr( submth(i), ...
                                             target, et, fixref,  ...
                                             abcorr, obsrvr );
      
               %
               % Now find the sub-spacecraft point.
               %
               
               [sscpt, trgepc, srfvec] = ...
                                        cspice_subpnt( submth(i), ...
                                              target, et, fixref, ...
                                              abcorr, obsrvr );
      
               %
               % Find the phase, solar incidence, and emission
               % angles at the sub-solar point on the Earth as seen
               % from MGS at time et.
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